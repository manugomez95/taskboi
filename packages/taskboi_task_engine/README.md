# Consuming the task engine

`taskboi_task_engine` is source-only (`publish_to: none`), so consumers resolve it
directly from the public repository rather than from pub.dev. Pin an immutable
commit using this exact dependency shape:

```yaml
dependencies:
  taskboi_task_engine:
    git:
      url: https://github.com/manugomez95/taskboi.git
      ref: b0e7d4b06ef22e547e3e044616dc85ab6a11e04f
      path: packages/taskboi_task_engine
```

The `ref` must be a full 40-hex commit SHA. Branches, tags, short SHAs, local
paths, SSH URLs, noncanonical URLs, and copied source are not supported.
