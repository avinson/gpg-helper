gpg-helper
==========

gpg-helper is a script for making multi-recipient gpg operations easier to use, specifically for use with the pass password manager. See here for more info on pass: http://www.passwordstore.org/

pass supports encryption for multiple recipients via placing multiple key IDs into a .gpg-id file. However, gpg itself does not provide an easy way of importing and trusting/verifying keys from a directory nor does it provide a way to easily list key IDs for export into a .gpg-id file for use with the pass utility. This helper script attempts to solve these issues.


## Prerequisites

The following docs assume that you have a ~/gpgkeys directory with several public gpg keys for people/team members with which you would like to share your pass database with. These keys should end in .asc, .key or .txt extensions. You should also have a recent version of pass installed (1.6 or higher)

## Common Tasks

* Import and trust (and sign) all public keys in a directory. Typically you would only do this with gpg keys from a known source. It's necessary for proper functioning of the pass utility to trust all keys that you're encrypting for.

```
gpg-helper.sh import_and_trust -d ~/gpgkeys
```

* List key IDs for a given directory (you would typically capture this to a .gpg-id file for pass)

```
gpg-helper.sh list_keys -d ~/gpgkeys > .gpg-id
```

## Considerations

The directory organization I intend to be used with this script is multiple sub-directories of keys for different teams in an organization such as ~/gpgkeys/operations, ~/gpgkeys/developers, ~/gpgkeys/it, etc. Then you can create a pass sub-directory that both operations and developers could access like this:

```
gpg-helper.sh list_keys -d ~/gpgkeys/operations > combined_keys.txt
gpg-helper.sh list_keys -d ~/gpgkeys/developers >> combined_keys.txt
pass init --path=Environments/Staging `cat combined_keys.txt`
```
