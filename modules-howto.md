# HOWTO: create a module

A module is a small Git repo that implements **one entrypoint** of **one stage**.
The benchmark pins a specific commit of your module via `repository.url` +
`repository.commit` in `benchmark_conda.yaml`.

## 1. Scaffold with `ob create module`

```bash
pip install omnibenchmark
ob create module --stage <stage-id> --template <template>
```

Pick a template that matches how you're packaging the work:

### tool-based (recommended when the tool is the unit of comparison)

Use when contributors want to benchmark **different functions of the same tool**
side-by-side. The module exposes one entrypoint per method, dispatched by
parameter.

```
my-scanpy-module/
├── run.py            # dispatcher: reads $parameter, calls the right fn
├── methods/
│   ├── pca.py
│   ├── nmf.py
│   └── ...
├── env.yml
└── README.md
```

Benchmark side:
```yaml
parameters:
  - method: ["pca", "nmf"]
```

Used today by: `pca-scanpy`, `pca-scrapper`.

### language-based (when the tool varies but the language doesn't)

Use when several R (or Python) tools implement the same step and you want one
conda env to cover them all. One module, one language, many tools.

```
filtering-r/
├── run.R
├── methods/
│   ├── manual.R
│   └── scrapper_auto.R
└── env.yml
```

Used today by: `filtering-r`, `normalization-r`, `selection-r`.

### single-method (smallest, easiest to review)

One module = one method. No dispatcher. Best for first-time contributors and
for methods with awkward dependencies that don't co-install cleanly with others.

```
my-method/
├── run.py
└── env.yml
```

> **Rule of thumb:** start with **single-method**. Promote to tool-based or
> language-based only once you have 2+ siblings that genuinely share an env.

## 2. Entrypoint contract

Every module's entrypoint receives, via CLI flags injected by omnibenchmark:

- `--input <key>=<path>` for each declared input
- `--output <key>=<path>` for each declared output
- `--<param-name> <value>` for each parameter

Write outputs to the exact paths given. Do not invent filenames.

## 3. Test locally against a sample

```bash
# from your module repo
git clone https://github.com/omni-scrna/contributing.git ../contributing

python run.py \
  --input rawdata.h5ad=../contributing/samples/one-data/datasets.h5ad \
  --output filtered.cellids=/tmp/out_cellids.txt.gz \
  --filter_type manual
```

If you produce a file at the declared `path`, you're done. Open a PR.

## 4. (Optional) run the validator

```bash
pixi run -- python ../split-stages-plan/validators/<stage>/<output_name>.py /tmp/out_cellids.txt.gz
```

Validators today are ad-hoc per stage. See
[validators/README.md](https://github.com/omni-scrna/split-stages-plan/tree/main/validators).
