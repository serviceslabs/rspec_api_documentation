Feature: Generate API Swagger documentation from test examples

  Background:
    Given a file named "app.rb" with:
      """
      require 'sinatra'

      class App < Sinatra::Base
        get '/orders' do
          content_type "application/vnd.api+json"

          [200, {
            :page => 1,
            :orders => [
              { name: 'Order 1', amount: 9.99, description: nil },
              { name: 'Order 2', amount: 100.0, description: 'A great order' }
            ]
          }.to_json]
        end

        get '/orders/:id' do
          content_type :json

          [200, { order: { name: 'Order 1', amount: 100.0, description: 'A great order' } }.to_json]
        end

        post '/orders' do
          content_type :json

          [201, { order: { name: 'Order 1', amount: 100.0, description: 'A great order' } }.to_json]
        end

        put '/orders/:id' do
          content_type :json

          if params[:id].to_i > 0
            [200, request.body.read]
          else
            [400, ""]
          end
        end

        delete '/orders/:id' do
          200
        end

        get '/instructions' do
          response_body = {
            data: {
              id: "1",
              type: "instructions",
              attributes: {}
            }
          }
          [200, response_body.to_json]
        end
      end
      """
    And   a file named "swagger.yml" with:
      """
      swagger: '2.0'
      info:
        title: Swagger Test App
        description: This is a sample of swagger API.
        termsOfService: 'http://swagger.io/terms/'
        contact:
          name: API Support
          url: 'http://www.swagger.io/support'
          email: support@swagger.io
        license:
          name: Apache 2.0
          url: 'http://www.apache.org/licenses/LICENSE-2.0.html'
        version: 1.0.1
      host: 'localhost:3000'
      schemes:
        - http
      consumes:
        - application/json
      produces:
        - application/json
      """
    And   a file named "app_spec.rb" with:
      """
      require "rspec_api_documentation"
      require "rspec_api_documentation/dsl"

      RspecApiDocumentation.configure do |config|
        config.app = App
        config.api_name = "Example API"
        config.format = :swagger
        config.swagger_config_path = "swagger.yml"
        config.request_body_formatter = :json
        config.request_headers_to_include = %w[Content-Type Host]
        config.response_headers_to_include = %w[Content-Type Content-Length]
      end

      resource 'Orders' do
        explanation "Orders resource"

        get '/orders' do
          explanation "This URL allows users to interact with all orders."

          example_request 'Getting a list of orders' do
            expect(status).to eq(200)
            expect(response_body).to eq('{"page":1,"orders":[{"name":"Order 1","amount":9.99,"description":null},{"name":"Order 2","amount":100.0,"description":"A great order"}]}')
          end
        end

        post '/orders' do
          explanation "This is used to create orders."

          header "Content-Type", "application/json"

          parameter :name, scope: :data
          parameter :description, scope: :data
          parameter :amount, scope: :data

          example 'Creating an order' do
            request = {
              data: {
                name: "Order 1",
                amount: 100.0,
                description: "A description"
              }
            }
            do_request(request)
            expect(status).to eq(201)
          end
        end

        get '/orders/:id' do
          explanation "This is used to return orders."

          let(:id) { 1 }

          example_request 'Getting a specific order' do
            explanation 'Returns a specific order.'

            expect(status).to eq(200)
            expect(response_body).to eq('{"order":{"name":"Order 1","amount":100.0,"description":"A great order"}}')
          end
        end

        put '/orders/:id' do
          explanation "This is used to update orders."

          parameter :name, 'The order name', required: true, scope: :data
          parameter :amount, required: false, scope: :data
          parameter :description, 'The order description', required: false, scope: :data

          header "Content-Type", "application/json"

          context "with a valid id" do
            let(:id) { 1 }

            example 'Update an order' do
              request = {
                data: {
                  name: 'order',
                  amount: 1,
                  description: 'fast order'
                }
              }
              do_request(request)
              expected_response = {
                data: {
                  name: 'order',
                  amount: 1,
                  description: 'fast order'
                }
              }
              expect(status).to eq(200)
              expect(response_body).to eq(expected_response.to_json)
            end
          end

          context "with an invalid id" do
            let(:id) { "a" }

            example_request 'Invalid request' do
              expect(status).to eq(400)
              expect(response_body).to eq("")
            end
          end
        end

        delete '/orders/:id' do
          explanation "This is used to delete orders."

          let(:id) { 1 }

          example_request "Deleting an order" do
            expect(status).to eq(200)
            expect(response_body).to eq('')
          end
        end
      end

      resource 'Instructions' do
        explanation 'Instructions help the users use the app.'

        get '/instructions' do
          explanation 'This should be used to get all instructions.'

          example_request 'List all instructions' do
            expected_response = {
              data: {
                id: "1",
                type: "instructions",
                attributes: {}
              }
            }
            expect(status).to eq(200)
            expect(response_body).to eq(expected_response.to_json)
          end
        end
      end
      """
    When  I run `rspec app_spec.rb --require ./app.rb --format RspecApiDocumentation::ApiFormatter`

  Scenario: Output helpful progress to the console
    Then  the output should contain:
      """
      Generating API Docs
        Orders
        GET /orders
          * Getting a list of orders
        POST /orders
          * Creating an order
        GET /orders/:id
          * Getting a specific order
        PUT /orders/:id
        with a valid id
          * Update an order
        with an invalid id
          * Invalid request
        DELETE /orders/:id
          * Deleting an order
        Instructions
        GET /instructions
          * List all instructions
      """
    And   the output should contain "7 examples, 0 failures"
    And   the exit status should be 0

  Scenario: Index file should look like we expect
    Then the file "doc/api/swagger.json" should contain exactly:
    """
    {
      "swagger": "2.0",
      "info": {
        "title": "Swagger Test App",
        "description": "This is a sample of swagger API.",
        "termsOfService": "http://swagger.io/terms/",
        "contact": {
          "name": "API Support",
          "url": "http://www.swagger.io/support",
          "email": "support@swagger.io"
        },
        "license": {
          "name": "Apache 2.0",
          "url": "http://www.apache.org/licenses/LICENSE-2.0.html"
        },
        "version": "1.0.1"
      },
      "host": "localhost:3000",
      "schemes": [
        "http"
      ],
      "consumes": [
        "application/json"
      ],
      "produces": [
        "application/json"
      ],
      "paths": {
        "/orders": {
          "get": {
            "tags": [
              "Orders"
            ],
            "summary": "Getting a list of orders",
            "description": "",
            "consumes": [

            ],
            "produces": [
              "application/vnd.api+json"
            ],
            "parameters": [

            ],
            "responses": {
              "200": {
                "description": "OK",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "application/vnd.api+json"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "137"
                  }
                },
                "examples": {
                  "application/vnd.api+json": {
                    "page": 1,
                    "orders": [
                      {
                        "name": "Order 1",
                        "amount": 9.99,
                        "description": null
                      },
                      {
                        "name": "Order 2",
                        "amount": 100.0,
                        "description": "A great order"
                      }
                    ]
                  }
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          },
          "post": {
            "tags": [
              "Orders"
            ],
            "summary": "Creating an order",
            "description": "",
            "consumes": [
              "application/json"
            ],
            "produces": [
              "application/json"
            ],
            "parameters": [
              {
                "name": "body",
                "in": "body",
                "description": "",
                "required": false,
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                    "data": {
                      "type": "object",
                      "properties": {
                        "name": {
                          "type": "string"
                        },
                        "description": {
                          "type": "string"
                        },
                        "amount": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              }
            ],
            "responses": {
              "201": {
                "description": "Created",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "application/json"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "73"
                  }
                },
                "examples": {
                  "application/json": {
                    "order": {
                      "name": "Order 1",
                      "amount": 100.0,
                      "description": "A great order"
                    }
                  }
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          }
        },
        "/orders/{id}": {
          "get": {
            "tags": [
              "Orders"
            ],
            "summary": "Getting a specific order",
            "description": "Returns a specific order.",
            "consumes": [

            ],
            "produces": [
              "application/json"
            ],
            "parameters": [
              {
                "name": "id",
                "in": "path",
                "description": "",
                "required": true,
                "type": "integer"
              }
            ],
            "responses": {
              "200": {
                "description": "OK",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "application/json"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "73"
                  }
                },
                "examples": {
                  "application/json": {
                    "order": {
                      "name": "Order 1",
                      "amount": 100.0,
                      "description": "A great order"
                    }
                  }
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          },
          "put": {
            "tags": [
              "Orders"
            ],
            "summary": "Update an order",
            "description": "",
            "consumes": [
              "application/json"
            ],
            "produces": [
              "application/json"
            ],
            "parameters": [
              {
                "name": "id",
                "in": "path",
                "description": "",
                "required": true,
                "type": "integer"
              },
              {
                "name": "body",
                "in": "body",
                "description": "",
                "required": false,
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                    "data": {
                      "type": "object",
                      "properties": {
                        "name": {
                          "type": "string"
                        },
                        "amount": {
                          "type": "string"
                        },
                        "description": {
                          "type": "string"
                        }
                      },
                      "required": [
                        "name"
                      ]
                    }
                  }
                }
              }
            ],
            "responses": {
              "200": {
                "description": "OK",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "application/json"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "63"
                  }
                },
                "examples": {
                }
              },
              "400": {
                "description": "Bad Request",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "application/json"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "0"
                  }
                },
                "examples": {
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          },
          "delete": {
            "tags": [
              "Orders"
            ],
            "summary": "Deleting an order",
            "description": "",
            "consumes": [
              "application/x-www-form-urlencoded"
            ],
            "produces": [
              "text/html"
            ],
            "parameters": [
              {
                "name": "id",
                "in": "path",
                "description": "",
                "required": true,
                "type": "integer"
              }
            ],
            "responses": {
              "200": {
                "description": "OK",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "text/html;charset=utf-8"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "0"
                  }
                },
                "examples": {
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          }
        },
        "/instructions": {
          "get": {
            "tags": [
              "Instructions"
            ],
            "summary": "List all instructions",
            "description": "",
            "consumes": [

            ],
            "produces": [
              "text/html"
            ],
            "parameters": [

            ],
            "responses": {
              "200": {
                "description": "OK",
                "schema": {
                  "description": "",
                  "type": "object",
                  "properties": {
                  }
                },
                "headers": {
                  "Content-Type": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "text/html;charset=utf-8"
                  },
                  "Content-Length": {
                    "description": "",
                    "type": "string",
                    "x-example-value": "57"
                  }
                },
                "examples": {
                  "text/html": {
                    "data": {
                      "id": "1",
                      "type": "instructions",
                      "attributes": {
                      }
                    }
                  }
                }
              }
            },
            "deprecated": false,
            "security": [

            ]
          }
        }
      },
      "tags": [
        {
          "name": "Orders",
          "description": "Orders resource"
        },
        {
          "name": "Instructions",
          "description": "Instructions help the users use the app."
        }
      ]
    }
    """

  Scenario: Example 'Deleting an order' file should not be created
    Then a file named "doc/api/orders/deleting_an_order.apib" should not exist

  Scenario: Example 'Getting a list of orders' file should be created
    Then a file named "doc/api/orders/getting_a_list_of_orders.apib" should not exist

  Scenario: Example 'Getting a specific order' file should be created
    Then a file named "doc/api/orders/getting_a_specific_order.apib" should not exist

  Scenario: Example 'Updating an order' file should be created
    Then a file named "doc/api/orders/updating_an_order.apib" should not exist

  Scenario: Example 'Getting welcome message' file should be created
    Then a file named "doc/api/help/getting_welcome_message.apib" should not exist
