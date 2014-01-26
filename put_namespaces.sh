curl --anyauth --user admin:admin -X PUT -d@./namespaces.xml \
    -H "Content-type: application/xml" \
    http://localhost:8070/v1/config/namespaces
