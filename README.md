#MPM

**MPM** stands for *minimal password manager*.

I think that password management should be done with open source software and I don't like KeePass.

This script is my first step in portable password management. Requires `pwgen` for password generation and `gpg` for file encryption.

You can export an editable `YAML` file with this command:

    mpm list > export.yaml

or the equivalent:

    gpg -o export.yaml file.asc

You can always access your passwords with `gpg`.
