# Active EVM Tasks

Active EVM tasks live under `tasks/<task-id>/`, with per-network task files under `config/<network>/`.

```text
active/evm/
├── Makefile
└── tasks/
    └── 2026-07-10-transfer-systemconfig-ownership/
        ├── FACILITATOR.md
        ├── config/
        │   └── zeronet/
        │       ├── .env
        │       ├── foundry.toml
        │       ├── network.env
        │       ├── README.md
        │       ├── lib/
        │       ├── script/
        │       └── validations/
        └── signatures/
            └── zeronet/
```

Run task commands from `active/evm`:

```bash
cd active/evm
make deps
make gen-validation-cb
make gen-validation-sc
```

The signer tool runs from `active/evm` and discovers date-prefixed task directories containing `config/<network>/validations`.
Task-origin signatures, when required, live under `tasks/<task-id>/signatures/<network>/`.
