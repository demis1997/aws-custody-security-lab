# Diagram sources

`render.py` contains declarative nodes/edges and a standard-library SVG renderer. Run `python3 architecture/diagrams/render.py` from repository root. The four SVGs are deterministic vector exports with selectable text, no scripts and no remote assets.

Arrows are representative paths, not a complete topology. The architecture diagram shows a coordinator-to-authorization relationship; responses carry bound evidence back. Dashed red paths identify an unsafe shared capability or a lost assumption. AWS resources, mTLS, custody software and disaster recovery have not been deployed.
