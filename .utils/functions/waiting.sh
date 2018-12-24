__spinner() {
    cub left
    cuf right
    cuu up
    cud down
}

/usr/bin/scp me@website.com:file somewhere 2> /dev/null &
pid=$! # Process Id of the previous running command

spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"

echo -n "[copying] ${spin[0]}"
while [ kill -0 $pid ]; do
    for i in "${spin[@]}"; do
        echo -ne "\b$i"
        sleep 0.1
    done
done
