# Merritt Dashboard (Merritt UI)

This microservice is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Purpose

This microservice provides the User Interface for the Merritt Perservation System.

This microservice provides API functionality for the [Dryad](https://datadryad.org/)
and for the harvesting of Nuxeo content feeds for ingest into Merrit. 

## Component Diagram

```mermaid
%%{init: {'theme': 'neutral', 'securityLevel': 'loose', 'themeVariables': {'fontFamily': 'arial'}}}%%
graph TD
  RDS[(Inventory DB)]
  UI("Merritt UI")
  click UI href "https://github.com/CDLUC3/mrt-dashboard" "source code"
  ING(Ingest)
  click ING href "https://github.com/CDLUC3/mrt-ingest" "source code"
  ST(Storage)
  click ST href "https://github.com/CDLUC3/mrt-store" "source code"
  LDAP[/LDAP\]
  NUXEO((Nuxeo DAMS))
  DRYAD(Dryad UI)
  click DRYAD href "https://datadryad.org/" "service link"
  NFEED[[Cron: Nuxeo Harvest]]
  BROWSER[[Browser]]

  subgraph Merritt
    BROWSER --> UI
    RDS --> UI
    UI --> |"file or manifest"| ING
    UI --> |authorization| LDAP
    UI ---> |retrieval req| ST
    NFEED --> ING
  end
  subgraph dryad_browse
    DRYAD --> |download req| UI
  end
  subgraph dams_ingest
    NUXEO --> NFEED
  end

  style RDS fill:#F68D2F
  style LDAP fill:cyan
  style NUXEO fill:cyan
  style DRYAD fill:cyan
  style UI stroke:red,stroke-width:4px
  style NFEED stroke:red,stroke-width:4px
```

## API Summary
[Swagger Documentation](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/CDLUC3/mrt-dashboard/main/swagger.yml)

## Dependencies

This code depends on the following Merritt Libraries.
- [UC3 SSM Gem](https://github.com/CDLUC3/uc3-ssm)

## For external audiences
This code is not intended to be run apart from the Merritt Preservation System.

See [Merritt Docker](https://github.com/CDLUC3/merritt-docker) for a description of how to build a test instnce of Merritt.

## Build instructions
Ruby bundler is used to build this application.

## Test instructions
GitHub Actions are used to test this application.

RSpec and Capybara tests exist for this application.

## Internal Links
- https://github.com/CDLUC3/mrt-doc-private/blob/main/uc3-mrt-ui.md
