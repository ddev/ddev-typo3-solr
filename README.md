# Apache Solr (standalone)

This add-on provides a Solr standalone (no cloud) service for ddev and
creates Solr cores according to the configuration defined in `.ddev/apache-solr/config.yaml`.

Because some Solr integrations (e.g. TYPO3 Solr) do not work
in cloud mode this add-on was created.

## Installation 

```bash
ddev get b13/ddev-apache-solr && ddev restart
```

### Create cores and its configuration:

Configuration example for TYPO3

```yaml
solr_config: 'vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/solr.xml'
configset: 'vendor/apache-solr-for-typo3/solr/Resources/Private/Solr/configsets/ext_solr_12_0_0'
cores:
  - name: "core_en"
    schema: "english/schema.xml"
  - name: "core_de"
    schema: "german/schema.xml"
```

```
ddev solrctl apply
```

### Delete cores and its configuration:

```
ddev solrctl wipe
```

> [!NOTE]  
> After running `wipe`, it may take a few seconds until files are synced which may 
> cause issues when running `apply` straight after `wipe`

### Running the solr control script

```
ddev solr -help
```

**Maintained by [@b13](https://github.com/b13)**
