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

            user_service = container "Delivery service" {
                description "Сервис доставки с API"
            }


            group "Слой данных" {
                user_database = container "Database" {
                    description "База данных"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кеши"
                    technology "Redis"
                    tags "database"
                }
            }

            user_service -> user_cache "Получение/обновление данных" 
            user_service -> user_database "Получение/обновление данных" 

            user -> user_service "Получение/обновление данных по АPI" 
        }

        user -> delivery_service "Получение/обновление данных о доставках"

        deploymentEnvironment "Production" {
            deploymentNode "User Server" {
                containerInstance delivery_service.user_service
                instances 3
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
            user -> delivery_service.user_service "Создать нового пользователя (POST /user)"
            delivery_service.user_service -> delivery_service.user_database "Сохранить данные о пользователе" 
        }

        dynamic delivery_service "UC02" "Поиск пользователя по логину или маске" {
            autoLayout
            user -> delivery_service.user_service "Поиск пользователя (GET /user)"
            delivery_service.user_service -> delivery_service.user_database "Поиск пользователя в БД" 
        }

        dynamic delivery_service "UC03" "Создание посылки" {
            autoLayout
            user -> delivery_service.user_service "Создание новой посылки пользовалетя (POST /parcel)"
            delivery_service.user_service -> delivery_service.user_database "Сохранить данные о посылке" 
        }

        dynamic delivery_service "UC04" "Получение посылок пользователя" {
            autoLayout
            user -> delivery_service.user_service "Получение посылок пользователя (GET /parcel)"
            delivery_service.user_service -> delivery_service.user_database "Получение данных о посылках" 
        }

        dynamic delivery_service "UC05" "Создание доставки" {
            autoLayout
            user -> delivery_service.user_service "Создание доставки (POST /delivery)"
            delivery_service.user_service -> delivery_service.user_database "Сохранить данные о доставке" 
        }

        dynamic delivery_service "UC06" "Получение данных о доставках" {
            autoLayout
            user -> delivery_service.user_service "Получение данных по пользователю (GET /delivery)"
            delivery_service.user_service -> delivery_service.user_database "Получение данных о доставках" 
        }

        styles {
            element "database" {
                shape cylinder
            }
        }
    }
}

