# NeuVector Image Scan Action

> [GitHub Action](https://github.com/features/actions) for [NeuVector Image Scans](https://neuvector.com)

[![GitHub Release][release-img]][release]
[![GitHub Marketplace][marketplace-img]][marketplace]
[![License][license-img]][license]

## Usage

### Scan container image

```yaml
name: build
on:
  push:
    branches:
      - main
jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Build image
        run: |
          docker build -t registry.organization.com/org/image-name:${{ github.sha }} .
      - name: Scan Image
        uses: bashofmann/neuvector-image-scan-action@main
        with:
          image-registry: registry.organization.com
          image-repository: org/image-name
          image-tag: ${{ github.sha }}
          min-high-cves-to-fail: '1'
          min-medium-cves-to-fail: '1'
```

## Customizing

### inputs

The following inputs can be used in `step.with`:

| Name                      | Type   | Default | Description                                                     |
|---------------------------|--------|---------|-----------------------------------------------------------------|
| `image-registry`          | String |         | Registry of the image to scan, e.g. `registry.organization.com` |
| `image-repository`        | String |         | Repository of the image to scan, e.g. `org/image-name`          |
| `image-tag`               | String |         | Tag of the image to scan, e.g. `1.0.0`                          |
| `min-high-cves-to-fail`   | String | `0`     | Minimum CVEs with high severity to fail the job                 |
| `min-medium-cves-to-fail` | String | `0`     | Minimum CVEs with medium severity to fail the job               |
| `cve-names-to-fail`       | String |         | Comma-separated list of CVE names that make the job fail        |

[release]: https://github.com/bashofmann/neuvector-image-scan-action/releases/latest
[release-img]: https://img.shields.io/github/release/bashofmann/neuvector-image-scan-action.svg?logo=github
[marketplace]: https://github.com/marketplace/actions/bashofmann/neuvector-image-scan
[marketplace-img]: https://img.shields.io/badge/marketplace-bashofmann/neuvector-image-scan--action-blue?logo=github
[license]: https://github.com/bashofmann/neuvector-image-scan-action/blob/master/LICENSE
[license-img]: https://img.shields.io/github/license/bashofmann/neuvector-image-scan-action