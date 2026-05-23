hiera-eyaml-age
===============

age encryption backend for [hiera-eyaml].

# Motivation

The default PKCS#7 encryption scheme used by `hiera-eyaml` works, but relies upon just a single key.

A solution that allows each team member and Puppet Server to hold their own keys allows for easier rotation.

[hiera-eyaml-gpg] supports each team member using their own keys, but.... it is GPG. Many may not be keen to get a degree in keyring management just to edit hieradata.

[age] supports encrypting to many with individual keys as well, but without the hassle. It offers meaningfully stronger encryption, even introducing post-quantum resistance since v1.3.0.

# Requirements

age [installed] in your `$PATH`.

# Install

```sh
gem install hiera-eyaml-age
```

# Configuration

```sh
# ~/.eyaml/config.yaml
age_identity_file: '/path/to/your/identity/file'
age_recipients: '<age_pubkey1>,<age_pubkey2>,...'
# age_recipients_file: '/path/to/recipients/file/pubkeys/one/per/line.txt'
# age_binary_path: '/optional/path/directly/to/age'
```

# Usage

## Encrypting and editing encrypted data

It is recommended to configure `hiera-eyaml` as above to avoid having to pass the necessary arguments each time.

The usual workflow can be as simple as `eyaml edit` and following the instructions at the top of the file:

```sh
eyaml edit /path/to/hieradata/file.yaml
```

Or more manually, create encrypted ``hiera-eyaml`` blocks encrypted with age:

```sh
eyaml encrypt --encrypt-method age --string "My string to encrypt" --age-recipients age126amywumzxvz2d9umnv3796tfsy044ww7pe7rwampammswl0n4rqv4c557,age162268ddynmjurmd7z628rctuh4qfavd84c62sjxhnmq7sw06c3lsmyetzf
```

Or pass a file containing a list of recipients (one per line, `#` comments ignored):

```sh
eyaml encrypt --encrypt-method age --string "My string to encrypt" --age-recipients-file /path/to/youur/recipients/file
```

age recipients can be native age public keys (`age1...`) or SSH public keys (`ssh-ed25519 ...`, `ssh-rsa ...`).

Use `eyaml --help` for more, or see the [hiera-eyaml] docs.

## Hardware keys and PKCS#11 tokens

If your age identity is protected by another factor (e.g. encrypted with a password, or an identity stored on a hardware security key) be aware that `hiera-eyaml` calls the encryptor once per encrypted value per file. Each call spawns a separate `age` process, which means one hardware interaction per encrypted value. This is a limitation of `hiera-eyaml`'s design, not of `age`.

### Configuring hiera

```yaml
---
version: 5
defaults:
hierarchy:
  - name: "Per-node data"
    lookup_key: eyaml_lookup_key
    options:
      age_identity_file: /opt/puppetlabs/server/data/puppetserver/.age/identity.txt
    path: "nodes/%{::trusted.certname}.yaml"
  - name: "Common data"
    lookup_key: eyaml_lookup_key
    options:
      age_identity_file: /opt/puppetlabs/server/data/puppetserver/.age/identity.txt
    path: "common.yaml"
```

### Installing on Puppet server

```sh
# Puppet agent and Server have separate Ruby environments
/opt/puppetlabs/puppet/bin/gem install hiera-eyaml-age
/opt/puppetlabs/server/bin/puppetserver gem install hiera-eyaml-age
```

[age]: https://age-encryption.org/
[hiera-eyaml-gpg]: https://github.com/voxpupuli/hiera-eyaml-gpg
[hiera-eyaml]: https://github.com/voxpupuli/hiera-eyaml
[installed]: https://age-encryption.org/#installation
