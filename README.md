[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ddev/ddev-typo3-solr/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ddev/ddev-typo3-solr/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ddev/ddev-typo3-solr)](https://github.com/ddev/ddev-typo3-solr/commits)
[![release](https://img.shields.io/github/v/release/ddev/ddev-typo3-solr)](https://github.com/ddev/ddev-typo3-solr/releases/latest)

# DDEV TYPO3 Solr

## Overview

[Apache Solr](https://solr.apache.org/) is the blazing-fast, open source, multi-modal search platform built on the full-text, vector, and geospatial search capabilities of Apache Lucene™.

This add-on integrates Solr into your [DDEV](https://ddev.com/) project and creates Solr cores according to the configuration defined in [`.ddev/typo3-solr/config.yaml`](typo3-solr/config.yaml).

This add-on is tailored to work with the TYPO3 extension `solr`. It now supports both server modes: standalone, solrcloud.

## Installation

```bash
ddev add-on get ddev/ddev-typo3-solr
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command                   | Description                                                           |
|---------------------------|-----------------------------------------------------------------------|
| `ddev solrctl --help`     | Create and destroy solr cores/collections and configsets              |
| `ddev solr-admin`         | Open Solr Admin in your browser                                       |
| `ddev solr`               | Run Solr CLI inside the Solr container                                |
| `ddev solr-zk`            | Run ZooKeeper CLI commands inside the Solr container (SolrCloud only) |
| `ddev describe`           | View service status and used ports for Solr                           |
| `ddev logs -s typo3-solr` | Check Solr logs                                                       |

## Configuration

### Create cores and its configuration

Configuration example for TYPO3 in `.ddev/typo3-solr/config.yaml`:

```yaml
config: 'vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/solr.xml'
typo3lib: "vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/typo3lib"
configsets:
    - name: "ext_solr_13_1_0"
      path: "vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/configsets/ext_solr_13_1_0"
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

### Switching between standalone and SolrCloud mode

Solr initializes its data directory at first boot in a mode-specific layout. Switching modes on an existing volume will fail — the volume must be removed first.

```bash
# Set the desired mode
ddev dotenv set .ddev/.env.typo3-solr --solr-mode="solrcloud"

ddev stop

# Remove the Solr volume (required when switching modes)
docker volume rm ddev-$(ddev status -j | docker run -i --rm ddev/ddev-utilities jq -r '.raw.name')_typo3-solr

ddev restart
ddev solrctl apply
```

Make sure to commit the `.ddev/.env.typo3-solr` file to version control.

### Using alternate versions of Solr

This addon defaults to installing a preferred version of the [docker Solr image](https://hub.docker.com/_/solr), but can be configured to use a different version via environment variable (`SOLR_BASE_IMAGE`).

Both **Solr 9.8+** and **Solr 10** are supported, in standalone and SolrCloud mode.

> [!IMPORTANT]
> Solr 10 removed `<lib/>` directives, several field types and the
> `stream.body` request parameter. Only use `solr:10` with an EXT:solr version
> (and configset) built for Solr 10 — older EXT:solr configsets are designed for
> Solr 9.x and may fail to load. If unsure, stay on the default `solr:9.x` image.

```bash
# Change image version as appropriate.
ddev dotenv set .ddev/.env.typo3-solr --solr-base-image="solr:10"

ddev add-on get ddev/ddev-typo3-solr

# Remove old solr volume (required for downgrades)
ddev stop
docker volume rm ddev-$(ddev status -j | docker run -i --rm ddev/ddev-utilities jq -r '.raw.name')_typo3-solr

# Rebuild solr image (required step)
ddev debug rebuild -s typo3-solr

ddev restart

# Confirm the new Solr version
ddev solr version
```

Make sure to commit the `.ddev/.env.typo3-solr` file to version control.

All customization options (use with caution):

| Variable          | Flag                | Default                                           |
|-------------------|---------------------|---------------------------------------------------|
| `SOLR_BASE_IMAGE` | `--solr-base-image` | `solr:9.10` (any `solr:9.8`+ or `solr:10` image)  |
| `SOLR_MODE`       | `--solr-mode`       | `standalone` (can be `standalone` or `solrcloud`) |

## Credits

**Maintained by [@b13](https://github.com/b13)**
