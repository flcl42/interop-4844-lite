
Start-Job -ScriptBlock {
    sleep 10 | Async
    echo "kek"
}
echo "kok"
