echo "IDSet"
SAFESERVER=152.54.14.38
curl  -v -X POST http://$SAFESERVER:7777/postIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"bphJZn3RJBnNqoCZk6k9SBD8mwSb054PXbwV7HpE80E\", \"otherValues\": [\"carrier\"] }"
curl  -v -X POST http://$SAFESERVER:7777/postIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"weQ8OFpXWhIB1AMzKX2SDJcxT738VdHCcl7mFlvOD24\", \"otherValues\": [\"alice\"] }"
curl  -v -X POST http://$SAFESERVER:7777/postIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"iMrcWFMgx6DJeLtVWvBCMzwd8EDtJtZ4L0n3YYn1hi8\", \"otherValues\": [\"bob\"] }"
curl  -v -X POST http://$SAFESERVER:7777/postIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"V1F2853Nq8V304Yb_GInYaWTgVqmBsQwC0tXWuNmmf8\", \"otherValues\": [\"pa\"] }"
curl  -v -X POST http://$SAFESERVER:7777/postIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"UIz4bXT7accigZ7KNpEyF2igwGOgXb9gne7p13i2bWA\", \"otherValues\": [\"pa\"] }"

curl  -v -X POST http://$SAFESERVER:7777/postSubjectSet -H "Content-Type: application/json" -d "{ \"principal\": \"bphJZn3RJBnNqoCZk6k9SBD8mwSb054PXbwV7HpE80E\", \"otherValues\": [] }"
curl  -v -X POST http://$SAFESERVER:7777/postSubjectSet -H "Content-Type: application/json" -d "{ \"principal\": \"weQ8OFpXWhIB1AMzKX2SDJcxT738VdHCcl7mFlvOD24\", \"otherValues\": [] }"
curl  -v -X POST http://$SAFESERVER:7777/postSubjectSet -H "Content-Type: application/json" -d "{ \"principal\": \"iMrcWFMgx6DJeLtVWvBCMzwd8EDtJtZ4L0n3YYn1hi8\", \"otherValues\": [] }"
curl  -v -X POST http://$SAFESERVER:7777/postSubjectSet -H "Content-Type: application/json" -d "{ \"principal\": \"V1F2853Nq8V304Yb_GInYaWTgVqmBsQwC0tXWuNmmf8\", \"otherValues\": [] }"
curl  -v -X POST http://$SAFESERVER:7777/postSubjectSet -H "Content-Type: application/json" -d "{ \"principal\": \"UIz4bXT7accigZ7KNpEyF2igwGOgXb9gne7p13i2bWA\", \"otherValues\": [] }"
