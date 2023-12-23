# Apache Solr Add-On for DDEV (standalone)

This DDEV add-on provides a Solr standalone (no cloud) service for DDEV and
creates Solr cores according to the configuration defined in `.ddev/apache-solr/config.yaml`.

This add-on is meant to be a simple integration for DDEV, as it does not
work with Solr Cloud and only for Solr standalone. Most web projects use
Solr in standalone-mode so this add-on simulates this behaviour for
local environments.

## Installation

```bash
ddev get b13/ddev-apache-solr && ddev restart
```

## Configuration

### Create cores and its configuration

Configuration example for TYPO3 in `.ddev/apache-solr/config.yaml`:

```yaml
config: 'vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/solr.xml'
configset:
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

### Delete cores and its configuration

```
ddev solrctl wipe
```

> [!NOTE]
> After running `wipe`, it may take a few seconds until files are synced which may
> cause issues when running `apply` straight after `wipe`.

### Running the solr control script

```
ddev solr -help
```

**Maintained by [@b13](https://github.com/b13)**
