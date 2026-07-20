#!/usr/bin/env python3
"""Repository-owned structural and semantic validation for SPDX 2.3 JSON."""

import argparse
import json
import re
import sys
from pathlib import Path

SPDX_ID = re.compile(r"^SPDXRef-[A-Za-z0-9.-]+$")
LICENSE_TOKEN = re.compile(r"\s*(\(|\)|AND\b|OR\b|WITH\b|[A-Za-z0-9.-]+\+?)")
LICENSE_REF = re.compile(r"^(?:DocumentRef-[A-Za-z0-9.-]+:)?LicenseRef-[A-Za-z0-9.-]+$")
EXTRACTED_LICENSE_ID = re.compile(r"^LicenseRef-[A-Za-z0-9.-]+$")
DATA_PATH = Path(__file__).with_name("data") / "spdx-license-list-3.27.0.json"


def load_spdx_identifiers() -> tuple[set[str], set[str]]:
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    if data.get("spdx_license_list_version") != "3.27.0":
        raise ValueError(f"unexpected SPDX License List version in {DATA_PATH}")
    if data.get("source") != "https://github.com/spdx/license-list-data/releases/tag/v3.27.0":
        raise ValueError(f"unexpected SPDX License List source in {DATA_PATH}")
    licenses, exceptions = data.get("licenses"), data.get("exceptions")
    if not isinstance(licenses, list) or not isinstance(exceptions, list):
        raise ValueError(f"invalid SPDX identifier data in {DATA_PATH}")
    return set(licenses), set(exceptions)


SPDX_LICENSES, SPDX_EXCEPTIONS = load_spdx_identifiers()


def valid_license_expression(value: object) -> bool:
    if value in ("NOASSERTION", "NONE"):
        return True
    if not isinstance(value, str) or not value:
        return False
    tokens = []
    position = 0
    while position < len(value):
        match = LICENSE_TOKEN.match(value, position)
        if not match:
            return False
        tokens.append(match.group(1))
        position = match.end()
    cursor = 0

    def primary() -> bool:
        nonlocal cursor
        if cursor < len(tokens) and tokens[cursor] == "(":
            cursor += 1
            if not expression() or cursor >= len(tokens) or tokens[cursor] != ")":
                return False
            cursor += 1
            return True
        if cursor < len(tokens) and (tokens[cursor] in SPDX_LICENSES or LICENSE_REF.fullmatch(tokens[cursor])):
            cursor += 1
            if cursor < len(tokens) and tokens[cursor] == "WITH":
                cursor += 1
                if cursor >= len(tokens) or tokens[cursor] not in SPDX_EXCEPTIONS:
                    return False
                cursor += 1
            return True
        return False

    def expression() -> bool:
        nonlocal cursor
        if not primary():
            return False
        while cursor < len(tokens) and tokens[cursor] in {"AND", "OR"}:
            cursor += 1
            if not primary():
                return False
        return True

    return expression() and cursor == len(tokens)


def local_license_references(value: object) -> set[str]:
    if not isinstance(value, str):
        return set()
    return {match.group(1) for match in LICENSE_TOKEN.finditer(value)
            if EXTRACTED_LICENSE_ID.fullmatch(match.group(1))}


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate(document: object) -> list[str]:
    errors: list[str] = []
    require(isinstance(document, dict), "document must be a JSON object", errors)
    if not isinstance(document, dict):
        return errors
    require(document.get("spdxVersion") == "SPDX-2.3", "spdxVersion must be SPDX-2.3", errors)
    require(document.get("dataLicense") == "CC0-1.0", "dataLicense must be CC0-1.0", errors)
    require(document.get("SPDXID") == "SPDXRef-DOCUMENT", "document SPDXID must be SPDXRef-DOCUMENT", errors)
    for field in ("name", "documentNamespace"):
        require(isinstance(document.get(field), str) and bool(document[field]), f"{field} must be a non-empty string", errors)
    namespace = document.get("documentNamespace", "")
    require(isinstance(namespace, str) and namespace.startswith(("https://", "http://", "urn:")),
            "documentNamespace must be an absolute HTTP(S) URL or URN", errors)
    creation = document.get("creationInfo")
    require(isinstance(creation, dict), "creationInfo must be an object", errors)
    if isinstance(creation, dict):
        require(bool(re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", str(creation.get("created", "")))),
                "creationInfo.created must be an SPDX UTC timestamp", errors)
        creators = creation.get("creators")
        require(isinstance(creators, list) and bool(creators) and
                all(isinstance(x, str) and re.match(r"^(Person|Organization|Tool): .+", x) for x in creators),
                "creationInfo.creators must contain valid creator strings", errors)

    packages = document.get("packages")
    require(isinstance(packages, list) and bool(packages), "packages must be a non-empty array", errors)
    extracted_infos = document.get("hasExtractedLicensingInfos", [])
    require(isinstance(extracted_infos, list), "hasExtractedLicensingInfos must be an array when present", errors)
    extracted_ids: set[str] = set()
    if isinstance(extracted_infos, list):
        for index, info in enumerate(extracted_infos):
            prefix = f"hasExtractedLicensingInfos[{index}]"
            require(isinstance(info, dict), f"{prefix} must be an object", errors)
            if not isinstance(info, dict):
                continue
            license_id = info.get("licenseId")
            require(isinstance(license_id, str) and bool(EXTRACTED_LICENSE_ID.fullmatch(license_id)),
                    f"{prefix}.licenseId is invalid", errors)
            require(isinstance(info.get("extractedText"), str) and bool(info["extractedText"]),
                    f"{prefix}.extractedText must be a non-empty string", errors)
            require(license_id not in extracted_ids, f"duplicate extracted license ID: {license_id}", errors)
            if isinstance(license_id, str):
                extracted_ids.add(license_id)
    ids = {"SPDXRef-DOCUMENT"}
    used_license_refs: set[str] = set()
    if isinstance(packages, list):
        for index, package in enumerate(packages):
            prefix = f"packages[{index}]"
            require(isinstance(package, dict), f"{prefix} must be an object", errors)
            if not isinstance(package, dict):
                continue
            identifier = package.get("SPDXID")
            require(isinstance(identifier, str) and bool(SPDX_ID.fullmatch(identifier)), f"{prefix}.SPDXID is invalid", errors)
            require(identifier not in ids, f"duplicate SPDXID: {identifier}", errors)
            if isinstance(identifier, str):
                ids.add(identifier)
            for field in ("name", "downloadLocation", "licenseConcluded", "licenseDeclared", "copyrightText"):
                require(isinstance(package.get(field), str) and bool(package[field]), f"{prefix}.{field} must be a non-empty string", errors)
            require(isinstance(package.get("filesAnalyzed"), bool), f"{prefix}.filesAnalyzed must be boolean", errors)
            for field in ("licenseConcluded", "licenseDeclared"):
                value = package.get(field)
                require(valid_license_expression(value), f"{prefix}.{field} is not a valid SPDX expression", errors)
                used_license_refs.update(local_license_references(value))

    for license_ref in sorted(used_license_refs - extracted_ids):
        errors.append(f"undefined extracted license ID: {license_ref}")

    files = document.get("files", [])
    require(isinstance(files, list), "files must be an array when present", errors)
    if isinstance(files, list):
        for index, file_entry in enumerate(files):
            prefix = f"files[{index}]"
            require(isinstance(file_entry, dict), f"{prefix} must be an object", errors)
            if not isinstance(file_entry, dict):
                continue
            identifier = file_entry.get("SPDXID")
            require(isinstance(identifier, str) and bool(SPDX_ID.fullmatch(identifier)), f"{prefix}.SPDXID is invalid", errors)
            require(identifier not in ids, f"duplicate SPDXID: {identifier}", errors)
            if isinstance(identifier, str):
                ids.add(identifier)
            require(isinstance(file_entry.get("fileName"), str) and bool(file_entry["fileName"]),
                    f"{prefix}.fileName must be a non-empty string", errors)
            checksums = file_entry.get("checksums")
            require(isinstance(checksums, list) and bool(checksums), f"{prefix}.checksums must be a non-empty array", errors)
            if isinstance(checksums, list):
                for checksum in checksums:
                    require(isinstance(checksum, dict) and checksum.get("algorithm") in {"SHA1", "SHA256", "SHA384", "SHA512", "MD5", "BLAKE2b-256", "BLAKE2b-384", "BLAKE2b-512", "BLAKE3", "ADLER32"}
                            and isinstance(checksum.get("checksumValue"), str) and bool(re.fullmatch(r"[0-9A-Fa-f]+", checksum["checksumValue"])),
                            f"{prefix} contains an invalid checksum", errors)

    has_document_describes = "documentDescribes" in document
    describes = document.get("documentDescribes", [])
    require(isinstance(describes, list), "documentDescribes must be an array when present", errors)
    if isinstance(describes, list):
        require(len(describes) == len(set(describes)), "documentDescribes contains duplicates", errors)
        for identifier in describes:
            require(identifier in ids - {"SPDXRef-DOCUMENT"}, f"documentDescribes references unknown ID: {identifier}", errors)
    relationships = document.get("relationships")
    require(isinstance(relationships, list), "relationships must be an array", errors)
    described = set()
    if isinstance(relationships, list):
        for index, relationship in enumerate(relationships):
            prefix = f"relationships[{index}]"
            require(isinstance(relationship, dict), f"{prefix} must be an object", errors)
            if not isinstance(relationship, dict):
                continue
            left, right = relationship.get("spdxElementId"), relationship.get("relatedSpdxElement")
            require(left in ids, f"{prefix}.spdxElementId references unknown ID: {left}", errors)
            require(right in ids, f"{prefix}.relatedSpdxElement references unknown ID: {right}", errors)
            require(isinstance(relationship.get("relationshipType"), str) and bool(relationship["relationshipType"]),
                    f"{prefix}.relationshipType must be a non-empty string", errors)
            if left == "SPDXRef-DOCUMENT" and relationship.get("relationshipType") == "DESCRIBES":
                described.add(right)
    # Syft omits documentDescribes, but still represents its scanned root
    # through at least one document-root DESCRIBES relationship.
    if isinstance(describes, list):
        if has_document_describes:
            require(described == set(describes), "DESCRIBES relationships must exactly match documentDescribes", errors)
        else:
            require(bool(described), "document without documentDescribes must include a document-root DESCRIBES relationship", errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("document", type=Path)
    args = parser.parse_args()
    try:
        document = json.loads(args.document.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"SPDX validation failed: {exc}", file=sys.stderr)
        return 1
    errors = validate(document)
    if errors:
        for error in errors:
            print(f"SPDX validation failed: {error}", file=sys.stderr)
        return 1
    print(f"Validated SPDX 2.3 structure and semantics: {args.document}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
