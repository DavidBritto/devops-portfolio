.
├── daily-exercises
│   ├── semana-1
│   │   ├── dia2-linux
│   │   │   └── README.md
│   │   ├── dia3-vagrant
│   │   │   ├── .gitignore
│   │   │   ├── html
│   │   │   │   └── index.html
│   │   │   ├── metada.json
│   │   │   ├── provision.sh
│   │   │   ├── .vagrant
│   │   │   │   ├── machines
│   │   │   │   └── rgloader
│   │   │   └── vagrantfile
│   │   ├── dia4-git
│   │   │   └── README.md
│   │   ├── dia5-scripting
│   │   │   ├── README.md
│   │   │   └── script-practica
│   │   │       ├── backup_log.sh
│   │   │       ├── buscador.sh
│   │   │       ├── cuestionario_loco.sh
│   │   │       ├── hola.sh
│   │   │       ├── mi_status.sh
│   │   │       ├── monitor_disco2.sh
│   │   │       ├── monitor_disco.sh
│   │   │       ├── monitor_servicio.sh
│   │   │       ├── multiplicador.sh
│   │   │       ├── presentacion.sh
│   │   │       ├── servicios-status.sh
│   │   │       ├── setup-webserver.sh
│   │   │       ├── tabla5.sh
│   │   │       └── venv
│   │   └── dia6-ansible
│   │       ├── freelancer
│   │       │   ├── files
│   │       │   ├── hosts
│   │       │   ├── playbooks.yml
│   │       │   ├── playbook.yml
│   │       │   ├── .vagrant
│   │       │   └── Vagrantfile
│   │       ├── .gitignore
│   │       ├── README.md
│   │       ├── tarea-practica
│   │       │   ├── ansible.cfg
│   │       │   ├── desplegar_app.yml
│   │       │   ├── inventories
│   │       │   ├── playbooks
│   │       │   ├── roles
│   │       │   ├── .vagrant
│   │       │   └── Vagrantfile
│   │       └── .vagrant
│   │           ├── machines
│   │           └── rgloader
│   ├── semana-2
│   │   ├── dia10-docker
│   │   │   └── README.md
│   │   ├── dia11-docker
│   │   │   └── README.md
│   │   ├── dia12-docker
│   │   │   └── README.md
│   │   ├── dia13-docker
│   │   │   └── README.md
│   │   └── dia9-docker
│   │       └── README.md
│   ├── semana-3
│   │   ├── dia15-ci-cd
│   │   │   └── README.md
│   │   ├── dia18-self-hosted
│   │   │   └── README.md
│   │   ├── dia19-docker-compose
│   │   │   └── README.md
│   │   └── dia20-monitoreo-y-logging
│   │       └── README.md
│   ├── semana-4
│   │   ├── dia-23
│   │   │   └── README.md
│   │   ├── dia-24
│   │   │   └── README.md
│   │   ├── dia-25
│   │   │   ├── README.md
│   │   │   ├── main.tf
│   │   │   └── modules/docker-webapp/
│   │   ├── dia-26
│   │   │   ├── README.md
│   │   │   ├── fase1-estado/
│   │   │   └── workspace/
│   │   ├── dia-27
│   │   │   └── README.md
│   │   └── dia-28
│   │       ├── README.md
│   │       ├── fase1-analisis.excalidraw
│   │       └── orquestacion-modulos.excalidraw
│   └── .vagrant
│       ├── machines
│       │   └── default
│       │       └── virtualbox
│       └── rgloader
│           └── loader.rb
├── .github
│   └── workflows
│       ├── ci.yml
│       ├── deploy-production.yml
│       ├── deploy-staging.yml
│       └── health-check.yml
├── .gitignore
├── mi-app
│   ├── app
│   │   ├── Dockerfile
│   │   ├── index.js
│   │   └── package.json
│   └── docker-compose.yml
├── README.md
├── REPO_TREE.md
└── voting-app
    ├── ansible.cfg
    ├── CHANGELOG.md
    ├── docs
    │   ├── 1.png
    │   ├── 2.png
    │   ├── 3.png
    │   ├── 4.png
    │   ├── 5.png
    │   └── 6.png
    ├── LICENCE
    ├── playbook.yml
    ├── README.md
    ├── roxs-voting-app
    │   ├── backups
    │   │   └── backup_development_20250709_174427.sql
    │   ├── docker-compose.prod.yml
    │   ├── docker-compose.staging.yml
    │   ├── docker-compose.yml
    │   ├── .env
    │   ├── load-testing
    │   │   └── k6.js
    │   ├── monitoring
    │   │   ├── grafana
    │   │   │   ├── dashboards
    │   │   │   ├── grafana.yml
    │   │   │   └── provisioning
    │   │   └── prometheus.yml
    │   ├── result
    │   │   ├── Dockerfile
    │   │   ├── main.js
    │   │   ├── .nvmrc
    │   │   ├── package.json
    │   │   ├── package-lock.json
    │   │   ├── tests
    │   │   │   └── main.test.js
    │   │   └── views
    │   │       ├── .DS_Store
    │   │       ├── index.html
    │   │       ├── js
    │   │       └── stylesheets
    │   ├── scripts
    │   │   ├── backup.sh
    │   │   ├── deploy.sh
    │   │   └── health-check.sh
    │   ├── startdocker.sh
    │   ├── terraform
    │   │   ├── modules
    │   │   │   ├── network/        (día 28)
    │   │   │   ├── database/       (día 28)
    │   │   │   ├── cache/          (día 28)
    │   │   │   ├── vote-service/   (día 28)
    │   │   │   ├── result-service/ (día 28)
    │   │   │   ├── worker-service/ (día 28)
    │   │   │   └── docker-webapp/  (monolito - referencia)
    │   │   ├── __backup
    │   │   │   ├── locals.tf
    │   │   │   ├── main.tf
    │   │   │   ├── outputs.tf
    │   │   │   └── variables.tf
    │   │   ├── docker_stack.tf
    │   │   ├── environments
    │   │   │   ├── dev.tfvars
    │   │   │   ├── prod.tfvars
    │   │   │   └── staging.tfvars
    │   │   ├── local.common_tags
    │   │   ├── local.current_env
    │   │   ├── local.resource_prefix
    │   │   ├── locals.tf
    │   │   ├── main.tf
    │   │   ├── outputs-docker.tf
    │   │   ├── outputs.tf
    │   │   ├── README.md
    │   │   ├── .terraform.lock.hcl
    │   │   ├── terraform.tfstate
    │   │   ├── terraform.tfstate.backup
    │   │   ├── terraform.tfvars
    │   │   ├── tfplan
    │   │   ├── time.tf
    │   │   ├── variables-docker.tf
    │   │   ├── variables.tf
    │   │   ├── var.project_name
    │   │   └── versions.tf
    │   ├── vote
    │   │   ├── app.py
    │   │   ├── Dockerfile
    │   │   ├── requirements.txt
    │   │   ├── templates
    │   │   │   └── index.html
    │   │   └── tests
    │   │       ├── lint_test.py
    │   │       └── test_app.py
    │   └── worker
    │       ├── Dockerfile
    │       ├── main.js
    │       ├── .nvmrc
    │       ├── package.json
    │       ├── package-lock.json
    │       └── tests
    │           └── main.test.js
    ├── start_all.sh
    ├── .vagrant
    │   ├── machines
    │   │   └── default
    │   │       └── virtualbox
    │   ├── provisioners
    │   │   └── ansible
    │   │       └── inventory
    │   └── rgloader
    │       └── loader.rb
    └── Vagrantfile

95 directories, 152 files
