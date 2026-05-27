# Floci + Terraform CI/CD Demo

Este proyecto es una demostración de cómo implementar un flujo de Integración Continua (CI) robusto para Infraestructura como Código (IaC) utilizando **Terraform** y construyendo/pusheando imágenes Docker a un Elastic Container Registry (ECR) efímero. 

Todo esto se logra utilizando **Floci**, sin necesidad de interactuar con la nube real de AWS, sin gestionar credenciales reales y sin gastar dinero.

## ¿Qué es Floci?

[Floci](https://github.com/floci-io/floci) es un emulador local de AWS de código abierto y extremadamente ligero. 
A diferencia de LocalStack, Floci:
- Levanta en milisegundos (~24 ms).
- No requiere cuentas, tokens de autenticación ni versiones de pago.
- Emula contenedores utilizando **ejecución real de Docker** (In-process con un registry real), perfecto para emular servicios como ECR de manera transparente.

## Arquitectura del Proyecto

El proyecto está diseñado bajo un estándar estricto de Arquitectura por Capas para Terraform, separando responsabilidades lógicas para mantener el código escalable:

### Estructura de Terraform

1. **Environments (`environments/`):** Define *dónde* se despliega la infraestructura. Aquí configuramos nuestro entorno `dev` para que el AWS Provider apunte todos sus endpoints a Floci (`http://localhost:4566`) y apague la validación de credenciales.
2. **Stacks (`stacks/`):** Define *qué* solución se arma. Nuestro `demo-stack` agrupa e instancia los módulos de negocio.
3. **Modules (`modules/`):** Define *cómo* se crea un recurso. Son bloques atómicos. Hemos implementado:
   - `s3` (Un bucket para archivos estáticos)
   - `dynamodb` (Una tabla NoSQL)
   - `ecr` (El repositorio destino de nuestro contenedor)

### Flujo de Ejecución (GitHub Actions)

El archivo `.github/workflows/ecr-ci.yml` orquesta el siguiente pipeline:

```mermaid
flowchart TD
    A[GitHub Actions Runner] -->|Inicia Service Container| B(Floci: puerto 4566)
    A -->|1. terraform init & apply| C[Infra en Memoria]
    C -.->|Crea Recursos| B
    A -->|2. docker build| D[Imagen Local]
    A -->|3. docker tag & push| B
    
    style B fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#ccf,stroke:#333
```

1. El runner levanta el contenedor de `floci/floci`.
2. Se ejecuta Terraform en `environments/dev`, lo cual provisiona el S3, la tabla DynamoDB y el repositorio ECR *falso* dentro del contenedor de Floci.
3. Construimos la imagen Docker de nuestra aplicación (basada en el `Dockerfile` y la carpeta `/app`).
4. Etiquetamos (tag) la imagen apuntando al puerto local `localhost:4566/dev-iac-floci-repo:latest`.
5. Pusheamos la imagen a nuestro registro local.

¡Al terminar el workflow, el runner muere y no queda basura en ninguna nube! CI 100% aislado.

## Ejecución Local

Si querés probar este flujo en tu máquina antes de enviarlo a GitHub:

1. **Levantá Floci** usando Docker Compose:
   ```bash
   docker compose up -d
   ```

2. **Configurá tus variables de AWS y ejecutá Terraform:**
   ```bash
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export AWS_DEFAULT_REGION=us-east-1
   export AWS_ENDPOINT_URL=http://localhost:4566

   cd environments/dev
   terraform init
   terraform apply -auto-approve
   cd ../..
   ```

3. **Build y Push del Contenedor usando el output de Terraform:**
   ```bash
   docker build -t dev-iac-floci-repo:latest .
   export REPO_URL=$(terraform -chdir=environments/dev output -raw ecr_repository_url)
   docker tag dev-iac-floci-repo:latest $REPO_URL:latest
   docker push $REPO_URL:latest
   ```

Una vez terminado, podés apagar el emulador y limpiar tu máquina con:
```bash
docker compose down
```
