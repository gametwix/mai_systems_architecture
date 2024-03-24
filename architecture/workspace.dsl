workspace {
    name "Сервис доставки"
    description "Система доставки посылок"

    # включаем режим с иерархической системой идентификаторов
    !identifiers hierarchical

    #!docs documentation
    #!adrs decisions
    # Модель архитектуры
    model {

        # Настраиваем возможность создания вложенных груп
        properties { 
            structurizr.groupSeparator "/"
        }
        

        # Описание компонент модели
        user = person "Пользователь системы доставки"
        delivery_service = softwareSystem "Сервис доставки" {
            description "Сервис для управления доставками"

            user_service = container "User service" {
                description "Данные об пользователе и авторизация"
            }

            boxdelivery_service = container "Delivery service" {
                description "Сервис работы с посылками и доставками"
            }

            api_gateway = container "API Gateway" {
                description "API Gateway"
            }


            group "Слой данных" {
                user_database = container "User Database" {
                    description "База данных"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кеши"
                    technology "Redis"
                    tags "database"
                }

                doc_database = container "Doc Database" {
                    description "База данных для посылок и доставок"
                    technology "MongoDB"
                    tags "database"
                }
            }

            api_gateway -> boxdelivery_service
            api_gateway -> user_service
            boxdelivery_service -> doc_database "Получение/обновление данных" 
            user_service -> user_cache "Получение/обновление данных" 
            user_service -> user_database "Получение/обновление данных" 

            user -> api_gateway "Получение/обновление данных по АPI" 
        }

        user -> delivery_service "Получение/обновление данных о доставках"

        deploymentEnvironment "Production" {
            deploymentNode "User Server" {
                containerInstance delivery_service.user_service
                instances 2
                properties {
                    "cpu" "2"
                    "ram" "2Gb"
                    "hdd" "10Gb"
                }
            }

            deploymentNode "Delivery Server" {
                containerInstance delivery_service.boxdelivery_service
                instances 2
                properties {
                    "cpu" "2"
                    "ram" "2Gb"
                    "hdd" "10Gb"
                }
            }

            deploymentNode "API Gateway" {
                containerInstance delivery_service.api_gateway
                instances 1
                properties {
                    "cpu" "2"
                    "ram" "2Gb"
                    "hdd" "10Gb"
                }
            }

            deploymentNode "databases" {
     
                deploymentNode "Database Server" {
                    containerInstance delivery_service.user_database
                }

                deploymentNode "Cache Server" {
                    containerInstance delivery_service.user_cache
                }

                deploymentNode "Doc Database Server" {
                    containerInstance delivery_service.doc_database
                }
            }
            
        }
    }

    views {
        themes default

        properties { 
            structurizr.tooltips true
        }


        !script groovy {
            workspace.views.createDefaultViews()
            workspace.views.views.findAll { it instanceof com.structurizr.view.ModelView }.each { it.enableAutomaticLayout() }
        }

        dynamic delivery_service "UC01" "Добавление нового пользователя" {
            autoLayout
            user -> delivery_service.api_gateway "Создать нового пользователя (POST /user)"
            delivery_service.api_gateway -> delivery_service.user_service "Создать нового пользователя (POST /user)"
            delivery_service.user_service -> delivery_service.user_database "Сохранить данные о пользователе" 
        }

        dynamic delivery_service "UC02" "Поиск пользователя по логину или маске" {
            autoLayout
            user -> delivery_service.api_gateway "Поиск пользователя (GET /user)"
            delivery_service.api_gateway -> delivery_service.user_service "Поиск пользователя (GET /user)"
            delivery_service.user_service -> delivery_service.user_database "Поиск пользователя в БД" 
        }

        dynamic delivery_service "UC03" "Создание посылки" {
            autoLayout
            user -> delivery_service.api_gateway "Авторизация пользователя (GET /login)"
            delivery_service.api_gateway -> delivery_service.user_service "Авторизация пользователя (GET /login)"
            delivery_service.user_service -> delivery_service.user_database "Получить данные о пользователе" 
            
            user -> delivery_service.api_gateway "Создание новой посылки пользовалетя (POST /parcel)"
            delivery_service.api_gateway -> delivery_service.boxdelivery_service "Создание новой посылки пользовалетя (POST /parcel)"
            delivery_service.boxdelivery_service -> delivery_service.doc_database "Создание новой посылки пользовалетя (POST /parcel)"
        }

        styles {
            element "database" {
                shape cylinder
            }
        }
    }
}

