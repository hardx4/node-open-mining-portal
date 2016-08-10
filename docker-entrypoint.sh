#!/bin/bash
set -e

if [ "$1" == node ]; then
        : "${REDIS_HOST:=127.0.0.1}"
        : "${REDIS_PORT:=6379}"
        : "${COIND_HOST:=127.0.0.1}"
        : "${COIND_PORT:=9998}"
        : "${COIND_USER:=dashrpc}"
        : "${COIND_PASSWORD:=mypassword}"
        : "${COIND_P2P_ENABLED:=false}"
        : "${COIND_P2P_HOST:=127.0.0.1}"
        : "${COIND_P2P_PORT:=9999}"
        : "${WEBSITE_ENABLED:=true}"
        : "${WEBSITE_PORT:=8080}"
        : "${POOL_ENABLED:=true}"

        if [ ! -e config.json ]; then
                awk '/^.*\"\/\/.*stop editing.*\"$/ && c == 0 { c = 1; system("cat") } { print }' config.json.example > config.json <<'EOJSON'
    "//": "nothing to be added :)",
EOJSON
        fi

        if [ ! -e pool_configs/dash.json ]; then
                awk '/^.*\"\/\/.*stop editing.*\"$/ && c == 0 { c = 1; system("cat") } { print }' pool_configs/dash.json.example > pool_configs/dash.json <<'EOJSON'
    "//": "nothing to be added :)",
EOJSON
        fi


        # see http://stackoverflow.com/a/2705678/433558
        sed_escape_lhs() {
                echo "$@" | sed 's/[]\/$*.^|[]/\\&/g'
        }
        sed_escape_rhs() {
                echo "$@" | sed 's/[\/&]/\\&/g'
        }
        set_config() {
                file=$1
                key=$2
                value=$3
                type=$4

                node <<EOJS

                var jsonfile = require('jsonfile');
                var _ = require('lodash');

                jsonfile.spaces = 4;

                var key = "$key";
                var value = "$value";
                var type = "$type";

                switch(type){
                        case "boolean":
                                value = isTrue(value);
                                break;
                        case "string":
                                value = value;
                                break;
                        case "float":
                                value = parseFloat(value);
                                break;
                        case "integer":
                                value = parseInt(value, 10);
                                break;
                        default:
                                value = value;
                }

                // read in the JSON file
                jsonfile.readFile('$file', function(err, obj) {
                        if (err) throw err;

                        // Using another variable to prevent confusion.
                        var fileObj = obj;

                        // Modify the file at the appropriate id
                        _.set(fileObj, key , value);

                        // Write the modified obj to the file
                        jsonfile.writeFile('$file', fileObj, function(err) {
                                if (err) throw err;
                        });
                });

                function isInt(n){
                        return Number(n) === n && n % 1 === 0;
                }

                function isFloat(n){
                        return Number(n) === n && n % 1 !== 0;
                }

                function isTrue(value){
                        if (typeof(value) == 'string'){
                                value = value.toLowerCase();
                        }
                        switch(value){
                                case true:
                                case "true":
                                case 1:
                                case "1":
                                case "on":
                                case "yes":
                                        return true;
                                default:
                                        return false;
                        }
                }

EOJS
        }

        set_config "config.json" "website.enabled" "$WEBSITE_ENABLED"                   	boolean
        set_config "config.json" "website.port" "$WEBSITE_PORT"                         	integer

        set_config "config.json" "redis.host" "$REDIS_HOST"                             	string
        set_config "config.json" "redis.port" "$REDIS_PORT"                             	integer

        set_config "config.json" "defaultPoolConfigs.redis.host" "$REDIS_HOST"          	string
        set_config "config.json" "defaultPoolConfigs.redis.port" "$REDIS_PORT"          	integer

        set_config "pool_configs/dash.json" "enabled" "$POOL_ENABLED"                   	boolean

        set_config "pool_configs/dash.json" "daemons[0].host" "$COIND_HOST"             	string
        set_config "pool_configs/dash.json" "daemons[0].port" "$COIND_PORT"             	integer
        set_config "pool_configs/dash.json" "daemons[0].user" "$COIND_USER"             	string
        set_config "pool_configs/dash.json" "daemons[0].password" "$COIND_PASSWORD"     	string

        set_config "pool_configs/dash.json" "p2p.enabled" "$COIND_P2P_ENABLED"          	boolean
        set_config "pool_configs/dash.json" "p2p.host" "$COIND_P2P_HOST"                	string
        set_config "pool_configs/dash.json" "p2p.port" "$COIND_P2P_PORT"                	integer
        
        set_config "pool_configs/dash.json" "paymentProcessing.enabled" "false"         	boolean
        
        set_config "pool_configs/dash.json" "address" "Xj14UwwzREn9itDKJLG9n3pjmeecLvBvoM"	string
        set_config "pool_configs/dash.json" "rewardRecipients.XivweVUQ3x3kUXMbQjc2eWrQGx3UN6edjq" "1.0"	float    
        
        sleep 15

fi

exec "$@"