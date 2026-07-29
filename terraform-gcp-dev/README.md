Estrategias de Optimización de Costos Aplicadas en el Entorno de Desarrollo (DEV):
Clúster de GKE Zonal (Single-Zone): En lugar de un clúster regional de alta disponibilidad distribuido en 3 zonas, desplegamos un clúster en una sola zona (us-central1-a). Esto elimina cargos por transferencia de datos interzonal y reduce el costo base.
100% Nodos SPOT: Todo el cómputo de desarrollo corre sobre instancias Spot (Preemptible), asegurando un ahorro de hasta un 80%. Al ser desarrollo, toleramos interrupciones controladas.
Tipos de Instancias Económicas: Reducimos la familia de máquinas de e2-standard-4 (4 vCPU, 16GB RAM) a e2-medium (2 vCPU, 4GB RAM) o e2-standard-2, que son ideales para pruebas y compilaciones rápidas.
Desactivación de Backups: Desactivamos el agente de copias de seguridad de GKE nativo (gke_backup_agent_config = false) para evitar costos por almacenamiento e infraestructura de datos efímeros o de prueba.
Reducción de Límites en Aplicaciones (Kubernetes): Ajustamos las réplicas a 1 sola instancia y establecemos reservas de CPU y memoria (resources.requests) sumamente bajas para compactar decenas de microservicios en muy pocos nodos.
