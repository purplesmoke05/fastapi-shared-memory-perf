#!/bin/bash

echo "Network Creating...."
docker network create normal_default >/dev/null 2>&1
docker network create shared_default >/dev/null 2>&1

echo "Build...."
docker build -t fastapi-py310-normal-mem-leak-test py3.10-normal >/dev/null 2>&1
docker build -t fastapi-py310-shared-mem-leak-test py3.10-shared >/dev/null 2>&1

echo "Start Server...."
docker run --name fastapi-py310-normal --network normal_default -p 15000:5000 -d fastapi-py310-normal-mem-leak-test >/dev/null 2>&1
docker run --name fastapi-py310-shared --network shared_default -p 15001:5000 -d fastapi-py310-shared-mem-leak-test >/dev/null 2>&1
echo "Initial Mem Usage"
echo "=========================================="
docker stats fastapi-py310-normal fastapi-py310-shared --no-stream --format "{{.Name}}: {{.MemUsage}}"
echo "=========================================="
echo "Run fastapi-py310-normal"
echo "=========================================="
echo "Run vegeta to Normal(300req/sec, 10sec)"
docker run --name normal-vegeta --rm --network normal_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py310-normal:5000/' | vegeta attack -rate=300 -duration=10s | tee results.bin | vegeta report"
echo "=========================================="
echo "Run fastapi-py310-shared"
echo "=========================================="
echo "Run vegeta to Shared(300req/sec, 10sec)"
docker run --name shared-vegeta --rm --network shared_default -i peterevans/vegeta sh -c "echo 'GET http://fastapi-py310-shared:5000/' | vegeta attack -rate=300 -duration=10s | tee results.bin | vegeta report"
echo "After Requests Mem Usage"
echo "=========================================="
docker stats fastapi-py310-normal fastapi-py310-shared --no-stream --format "{{.Name}}: {{.MemUsage}}"
docker exec -it fastapi-py310-shared bash -c "ps -ef | grep [g]unicorn | awk '{print \$2}' | xargs -I{} ls -al /proc/{}/fd | grep sm_tokens"
echo "=========================================="
echo "=[LOG] Processed successfully(Normal)====="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Normal)="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Normal)=============="
bash -c "docker logs fastapi-py310-normal 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-normal 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"

echo "=[LOG] Processed successfully(Shared)====="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep thread= | grep -c {})'"

echo "=[LOG] Exceeded concurrency limit(Shared)="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep limit | grep -c {})'"

echo "=[LOG] Shutting down(Shared)=============="
bash -c "docker logs fastapi-py310-shared 2>&1 | grep 'Started' | awk -F'[][]' '{print \$4}' | xargs -n 1 -I{} sh -c 'docker logs fastapi-py310-shared 2>&1 | echo PID: {}, OutputLogs: \$(grep Shutting | grep -c {})'"
echo "=[LOG] Cached Memory(Shared)=============="
docker logs fastapi-py310-shared 2>&1 | grep  Extend
docker logs fastapi-py310-shared
echo "=========================================="
echo "Cleanup...."
docker stop fastapi-py310-normal fastapi-py310-shared >/dev/null 2>&1
docker stop normal-vegeta shared-vegeta >/dev/null 2>&1
echo "=========================================="
docker rm fastapi-py310-normal fastapi-py310-shared >/dev/null 2>&1
docker rm normal-vegeta shared-vegeta >/dev/null 2>&1
docker network rm normal_default shared_default >/dev/null 2>&1
