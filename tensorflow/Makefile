all:
	python -m pip install -r requirements.txt

.PHONY: dev
dev: all
	python -m pip install -r dev_requirements.txt

.PHONY: venv
venv:
	python3 -m venv venv

.PHONY: venv-remove
venv-remove:
	rm -rf ./venv

.PHONY: notebook
notebook:
	python -m jupyter notebook
