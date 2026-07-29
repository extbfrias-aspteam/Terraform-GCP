# Terraform-GCP
Deploy de infraestructura GCP
# Guía de Despliegue de Infraestructura y GitOps de Producción GKE

Este documento describe detalladamente el procedimiento para inicializar, aplicar la infraestructura de producción mediante Terraform en el proyecto `prj-hypertech-prod` y configurar la sincronización automática de aplicaciones utilizando **GKE Config Sync**.

## Requisitos Previos

1. Instalar la suite de herramientas: [gcloud CLI](https://cloud.google.com/sdk/docs/install) y [kubectl](https://kubernetes.io/docs/tasks/tools/).
2. Autenticar su sesión y definir el proyecto de producción activo:
   ```bash
   gcloud auth login
   gcloud config set project prj-hypertech-prod


Activar los servicios de GCP necesarios en el proyecto destino:


gcloud services enable \
    container.googleapis.com \
    compute.googleapis.com \
    anthosconfigmanagement.googleapis.com

    Paso 1: Configurar el Almacenamiento del Estado de Terraform
Antes de ejecutar Terraform, es mandatorio crear el bucket de Google Cloud Storage que servirá como backend remoto seguro:


# Crear bucket de almacenamiento en la región del proyecto
gcloud storage buckets create gs://prj-hypertech-prod-tfstate \
    --project=prj-hypertech-prod \
    --location=us-central1 \
    --uniform-bucket-level-access

# Activar la retención de versiones del estado para evitar pérdidas accidentales
gcloud storage buckets update gs://prj-hypertech-prod-tfstate --versioning


aso 2: Inicializar y Desplegar Terraform
Navegue al directorio raíz del repositorio de infraestructura terraform-gcp-prod:

# 1. Copiar y configurar las variables específicas del entorno
cp terraform.tfvars.example terraform.tfvars

# [Modifique terraform.tfvars según los rangos de red reales de Producción]

# 2. Inicializar el backend de Terraform descargando los proveedores
terraform init

# 3. Validar sintáctica y lógicamente los manifiestos creados
terraform validate

# 4. Generar y revisar el plan de ejecución detallado
terraform plan -out=tfplan.binary

# 5. Aplicar el plan validado para levantar la infraestructura de GKE
terraform apply tfplan.binary



Al finalizar exitosamente el proceso de aprovisionamiento, se mostrarán las variables de salida en su pantalla. Utilice el comando del output para conectarse a su nuevo clúster de producción:

# Conectar credenciales de kubectl al clúster de GKE en Producción
gcloud container clusters get-credentials banking-cluster-prod --region us-central1 --project prj-hypertech-prod




Paso 3: Configurar el Repositorio de GitOps y GKE Config Sync
A. Estructurar el Repositorio GitOps
Cree un repositorio en GitHub u otro hosting Git de su organización bajo el nombre gitops-gcp-prod. Copie la estructura descrita en el apartado de GitOps y suba los cambios a la rama principal:

git init
git checkout -b main
git add .
git commit -m "feat: initial GKE production gitops manifests structure"
git remote add origin https://github.com/hypertech-org/gitops-gcp-prod.git
git push -u origin main

B  Instalar Config Sync en el Clúster de GKE
Habilite la función de administración de configuraciones dentro de su clúster GKE:

# Habilitar Anthos Config Management en el clúster
gcloud container fleet memberships register banking-cluster-prod-membership \
   --gke-cluster=us-central1/banking-cluster-prod \
   --enable-workload-identity

# Instalar los componentes de Config Sync
gcloud container fleet config-management enable

# Crear el archivo de configuración del operador de sincronización
cat <<EOF > config-management.yaml
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  # Desplegar Config Sync
  configSync:
    enabled: true
    sourceFormat: unstructured
EOF

# Aplicar configuración para instalar Config Sync
kubectl apply -f config-management.yaml


C. Configurar el Acceso Seguro al Repositorio de Git
Para que Config Sync pueda leer nuestro repositorio de GitOps privado, debemos crear un Token de Acceso Personal (PAT) con permisos de lectura en Git y guardarlo como Secreto de Kubernetes:

# Crear el Namespace del sistema de gestión si no existe
kubectl create namespace config-management-system || true

# Guardar el token de Git como secreto dentro del namespace dedicado
kubectl create secret generic git-creds \
  --namespace=config-management-system \
  --from-literal=username=gitops-bot \
  --from-literal=token=<SU_PERSONAL_ACCESS_TOKEN_AQUÍ>


D Aplicar el RootSync para Iniciar la Conciliación GitOps
Aplique el manifiesto de RootSync generado previamente para que Config Sync lea la rama main de su repositorio GitOps y cree los namespaces, deployments y servicios de forma autónoma:

# Aplicar el RootSync para iniciar el lazo de conciliación automática
kubectl apply -f config-sync/rootsync.yaml

# Monitorear el estado de sincronización del clúster en tiempo real
nomos status



El comando nomos status le confirmará cuándo los recursos de producción han pasado a estado SYNCED, garantizando que la migración ha concluido de forma exitosa y segura.


