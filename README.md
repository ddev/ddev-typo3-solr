[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ddev/ddev-typo3-solr/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ddev/ddev-typo3-solr/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ddev/ddev-typo3-solr)](https://github.com/ddev/ddev-typo3-solr/commits)
[![release](https://img.shields.io/github/v/release/ddev/ddev-typo3-solr)](https://github.com/ddev/ddev-typo3-solr/releases/latest)

# DDEV TYPO3 Solr (standalone)

## Overview

[Apache Solr](https://solr.apache.org/) is the blazing-fast, open source, multi-modal search platform built on the full-text, vector, and geospatial search capabilities of Apache Lucene™.

This add-on integrates Solr standalone (no cloud) into your [DDEV](https://ddev.com/) project and creates Solr cores according to the configuration defined in [`.ddev/typo3-solr/config.yaml`](typo3-solr/config.yaml).

This add-on is meant to be a simple integration for DDEV, as it does not work with Solr Cloud and only for Solr standalone. Most web projects use Solr in standalone-mode so this add-on simulates this behaviour for local environments.

## Installation

```bash
ddev add-on get ddev/ddev-typo3-solr
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev solrctl --help` | Create and destroy solr cores and configsets |
| `ddev solr` | Run Solr CLI inside the Solr container |
| `ddev launch :8984` | Open Solr Admin in your browser (`https://<project>.ddev.site:8984`) |
| `ddev describe` | View service status and used ports for Solr |
| `ddev logs -s typo3-solr` | Check Solr logs |

## Configuration

### Create cores and its configuration

Configuration example for TYPO3 in `.ddev/typo3-solr/config.yaml`:

```yaml
config: 'vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/solr.xml'
typo3lib: "vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/typo3lib"
configsets:
    - name: "ext_solr_12_0_0"
      path: "vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/configsets/ext_solr_12_0_0"
      cores:
          - name: "core_en"
            schema: "english/schema.xml"
          - name: "core_de"
            schema: "german/schema.xml"
```

```bash
ddev solrctl apply
```

To ensure the cores are created automatically on boot, add the following hook to your `.ddev/config.yaml`:

```yaml
hooks:
  post-start:
    - exec-host: ddev solrctl apply
```

### Example configuration for TYPO3

To connect to the solr service you have to configure the following lines in your site configuration:

```yaml
solr_enabled_read: true
solr_host_read: <your-site>.ddev.site
solr_path_read: /
solr_port_read: '8984'
solr_scheme_read: https
```

### Delete cores and its configuration

```bash
ddev solrctl wipe
```

> [!NOTE]
> After running `wipe`, it may take a few seconds until files are synced which may
> cause issues when running `apply` straight after `wipe`.

### Running the solr control script

```bash
ddev solr
```

## Advanced Customization

### Using alternate versions of Solr

This addon defaults to installing a preferred version of the [docker Solr image](https://hub.docker.com/_/solr), but can be configured to use a different version via environment variable (`SOLR_BASE_IMAGE`).

```bash
# Change image version as appropriate.
ddev dotenv set .ddev/.env.solr --solr-base-image="solr:9.8"

ddev add-on get ddev/ddev-typo3-solr

# remove old solr volume (if this is downgrade)
ddev stop
docker volume rm ddev-$(ddev status -j | docker run -i --rm ddev/ddev-utilities jq -r '.raw.name')_typo3-solr

# rebuild solr image (required step)
ddev debug rebuild -s typo3-solr

ddev restart

# confirm the new Solr version
ddev solr version
```

Make sure to commit the `.ddev/.env.solr` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `SOLR_BASE_IMAGE` | `--solr-base-image` | `solr:9.8` |

## Credits

**Maintained by [@b13](https://github.com/b13)**
