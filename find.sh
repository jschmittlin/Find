#!/bin/dash
#Déclaration des fonctions pour la gestion des arguments
#fonction qui va afficher l'aide
help() {
    echo "usage : $0 [DIR] [OPTION]...

Search for files in a directory hierarchy DIR.
If DIR is not specified, the search is performed in the current directory.

OPTIONS
    --help              show help and exit
    -name PATTERN       Finding files whose name match the shell pattern PATTERN
                        The pattern must be a nonempty string with no white-space
                        characters
    -type {d|f}         Finding files that are directories (type d)
                        or regular files (type f)
    -size [+|-]SIZE     Finding files whose size is greater than or equal(+), or less
                        than or equal (-), or equal to SIZE
    -exe COMMAND        Run the command COMMAND for each file found instead of
                        displaying its path
                        In the string COMMAND, each pair of braces {} will be replaced
                        by the path to the found file
                        The string COMMAND must contain at least one pair of braces {}"
}
#fonction qui permet d'afficher une erreur lorsque qu'on a utilisé une option plus de une fois
printerror() {
    echo "The predicate $1 must be used only one time"
}
#fonction qui invite utilisateur à utiliser l'option '--help'
getsomehelp() {
    echo "Enter '$0 --help' for more information"
}

#Déclaration des variables
WHERE=$(dirname $0)     #chemin du répertoire (répertoire courant par défault)
NAME=false              #présence de l'option -name
TYPE=false              #présence de l'option -type
SIZE=false              #présence de l'option -size
EXE=false               #présence de l'option -exe
COUNT=0                 #compteur pour vérifier la position des arguments
PATTERN=false           #pattern indiquer
COMMAND=false           #command indiquer
SIGN=false               #opérateur en fonction du signe de la variable '$SIZE'
NOMBRE=$SIZE            #size sans le signe

#Vérification de tout les arguments
#Vérification du prédicat '--help'
if test $# -eq 1
then
    if test $1 = "--help"
    then
        help
        exit 1
    fi
fi
#Vérification des autres arguments
for args in $@
do
    COUNT=$(($COUNT+1)) #incrémentation compteur
#Vérification des prédicats existants
    #Vérifie si c'est une option avec '-'
    if test $(echo $args | cut -c 1) = "-" && ! test $SIZE = "true" #size inférieur ou égale
    then
        #Vérifie si c'est une option connue
        if ! test $args = "-name" && ! test $args = "-type" && ! test $args = "-size" && ! test $args = "-exe" && ! test $args = "--help"
        then
            echo "Error : unknown predicate '$args'"
            getsomehelp
            exit 1
        fi
    fi
#Vérification des arguments
    #Vérification de l'argument 'dir'
    if ! test $(echo $args | cut -c 1) = "-"
    then
        #Vérifie si ce n'est pas un argument d'une autre option
        if test $COUNT -ne 1 && test $NAME = "false" && test $EXE = "false" && ! test $SIZE = "true" && ! test $TYPE = "true"
        then
            echo "Error : paths must precede expression: '$args'"
            getsomehelp
            exit 1
        fi
        #Vérifie s'il se situe avant les autres options
        if test $COUNT -eq 1
        then
            #Vérifie si c'est bien un répertoire
            if ! test -d $args 2>/dev/null
            then
                echo "Error : '$args': No such directory"
                getsomehelp
                exit 1
            fi
            WHERE=$args
        fi
    fi
    #Vérification de l'argument 'pattern'
    if test $NAME = "true"
    then
        #Vérifie s'il contient un espace et qu'il n'est pas vide
        if echo $args | grep -q "[[:space:]]" || test -z $args 2>/dev/null
        then
            echo "Error : Invalid argument '$args' to -name"
            getsomehelp
            exit 1
        fi
        PATTERN=$args
        NAME="false"
    fi
    #Vérification de l'argument 'type'
    if test $TYPE = "true"
    then
        #Vérifie si l'argument est connu
        if test $args != "d" && test $args != "f"
        then
            echo "Error : Unknown argument to -type: $args"
            getsomehelp
            exit 1
        fi
        TYPE=$args
    fi
    #Vérification de l'argument 'size'
    if test $SIZE = "true"
    then
        #Vérifie si c'est bien un nombre
        if ! test $args -eq $args 2>/dev/null
        then
            echo "Error : Invalid argument '$args' to -size"
            getsomehelp
            exit 1
        fi
        SIZE=$args
    fi
    #Vérification de l'argument 'command'
    if test $EXE = "true"
    then
        #Vérifie si '{}' est présent 
        if ! echo $args | grep -q "{}"
        then
            echo "Error : Invalid argument '$args' to -exe"
            getsomehelp
            exit 1
        fi
        COMMAND=$args
        EXE="false"
    fi
#Vérification de la présence et de unicité des prédicats
    #Vérification du prédicat '--help'
    if test $args = "--help"
    then
        echo "Error : predicate '$args' must be used alone"
        getsomehelp
        exit 1
    fi
    #Vérification du prédicat '-name'
    if test $args = "-name"
    then
        #Vérifie si l'option '-name' n'est pas déjà utilisée
        if test $NAME = "true"
        then
            printerror $args
            getsomehelp
            exit 1
        fi
        #Vérification de la présence d'argument après le prédicat '-name'
        if test $COUNT = $#
        then
            echo "Error : missing argument to '$args'"
            getsomehelp
            exit 1
        fi
        NAME=true
    fi
    #Vérification du prédicat '-type'
    if test $args = "-type"
    then
        #Vérifie si l'option '-type' n'est pas déjà utilisée ou initialisée
        if test $TYPE = "true" || test $TYPE = "f" || test $TYPE = "d"
        then
            printerror $args
            getsomehelp
            exit 1
        fi
        #Vérification de la présence d'argument après le prédicat '-type'
        if test $COUNT = $#
        then
            echo "Error : missing argument to '$args'"
            getsomehelp
            exit 1
        fi
        TYPE=true
    fi
    #Vérification du prédicat '-size'
    if test $args = "-size"
    then
        #Vérifie si l'option '-size' n'est pas déjà utilisée
        if test $SIZE = "true" || test $SIZE -eq $SIZE 2>/dev/null
        then
            printerror $args
            getsomehelp
            exit 1
        fi
        #Vérification de la présence d'argument après le prédicat '-size'
        if test $COUNT = $#
        then
            echo "Error : missing argument to '$args'"
            getsomehelp
            exit 1
        fi
        SIZE=true
    fi
    #Vérification du prédicat '-exe'
    if test $args = "-exe"
    then
        #Vérifie si l'option '-exe' n'est pas déjà utilisée
        if test $EXE = "true"
        then
            printerror $args
            getsomehelp
            exit 1
        fi
        #Vérification de la présence d'argument après le prédicat '-exe'
        if test $COUNT = $#
        then
            echo "Error : missing argument to '$args'"
            getsomehelp
            exit 1
        fi
        EXE=true
    fi
done 

#Déclaration des fonctions pour l'execute de la commande find.sh
#Fonction qui permet de savoir quel signe et la variable '$SIZE'
#   @parametre $1      un nombre
#   @renvoie   -eq     si aucun signe est présent
#   @renvoie   -ge     si le signe '+' est présent
#   @renvoie   -le     si le signe '-' est présent
#   @renvoie   false   si le signe 'false' est présent
getsign() {
    if test $(echo $1 | cut -c 1) = "+"
    then
        SIGN="ge"
    fi
    if test $(echo $1 | cut -c 1) = "-"
    then
        SIGN="le"
    fi
    if ! test $(echo $1 | cut -c 1) = "+" && ! test $(echo $1 | cut -c 1) = "-"
    then
        SIGN="eq"
    fi
    if test $1 = "false"
    then
        SIGN=false
    fi
    echo $SIGN
}
#Fonction enlève le signe de la variable '$SIZE' ('+' ou '-')
#   @parametre $1      un nombre
#   @renvoie           un nombre
getnombre() {
    echo $1 | sed 's/-//' | sed 's/+//'
}
#Fonction qui sélectionne par rapport à l'option '-type'
#   @parametre $1      un chemin
#   @parametre $2      'f' ou 'd' ou 'false'
#   @renvoie           un chemin
type() {
    #Paramètres
    FILE=$1
    TYPE=$2

    #L'option '-type' n'est pas présente -> Afficher le chemin des fichiers et répertoires
        if test $TYPE = "false" 2>/dev/null
        then
            #Vérifie si c'est un ficher -> Afficher le chemin
            if test -f $FILE
            then
                echo $FILE
            fi
            #Vérifie si c'est un répertoire -> Afficher le répertoire
            #                               -> Rappeller la fonction 'ls'
            if test -d $FILE
            then
                echo $FILE
                ls $FILE $PATTERN $SIGN $SIZE $TYPE
            fi
        else
    #L'option '-type' est présente
        #Afficher le chemin des répertoires
            if test $TYPE = "d" 2>/dev/null
            then
                #Vérifie si c'est un répertoire -> Afficher le répertoire
                #                               -> Rappeller la fonction 'ls'
                if test -d $FILE
                then
                    echo $FILE
                    ls $FILE $PATTERN $SIGN $SIZE $TYPE
                fi
            fi
        #Afficher le chemin des fichiers
            if test $TYPE = "f" 2>/dev/null
            then
                #Vérifie si c'est un ficher -> Afficher le chemin
                if test -f $FILE
                then
                    echo $FILE
                fi
                #Vérifie si c'est un répertoire -> Rappeller la fonction 'ls'                     
                if test -d $FILE
                then
                    ls $FILE $PATTERN $SIGN $SIZE $TYPE
                fi
            fi
	    fi
}
#Fonction qui sélectionne par rapport à l'option '-size'
#   @parametre $1      un chemin
#   @parametre $2      'eq' ou 'le' ou 'ge' ou 'false'
#   @parametre $3      un nombre
#   @renvoie           un chemin
size() {
    #Paramètres
    FILE=$1
    SIGN=$2
    NOMBRE=$3

    #L'option '-size' n'est pas présente -> Afficher le chemin
    if test $SIGN = "false"
    then
        echo $FILE
    else
    #L'option '-size' est présente
        #Vérifie si c'est un ficher ou un répertoire -> Récupérer la taille d'un fichier
        if test -f $FILE || test -d $FILE
        then
            SIZE=$(du -b -c $FILE | cut -f1 | tail -1)
            #SIZE=$(stat -c %s $FILE)
        fi
        #Vérifier en fonction des options -> Afficher le chemin
        if test $SIZE -$SIGN $NOMBRE 2>/dev/null
        then
            echo $FILE
        fi
    fi
}
#Fonction qui sélectionne par rapport à l'option '-name'
#   @parametre $1      un chemin
#   @parametre $2      une chaîne
#   @renvoie           un chemin
name() {
    #Paramètres
    FILE=$1
    PATTERN=$2

    #L'option '-name' n'est pas présente -> Afficher le chemin
    if test $PATTERN = "false" 2>/dev/null
    then
        echo $FILE
    else
    #L'option '-name' est présente
        for I in $PATTERN
        do
            #Vérifie que le fichier correspond au pattern -> Afficher le chemin
            if echo $(basename $FILE) | grep -w -q $I 2>/dev/null   #basename pour éviter qui prennent tous les fichiers d'un répertoire qui porte le nom du pattern
            then
                echo $FILE
            fi
        done
    fi
}
#Fonction ls++
#   @parametre $1      un chemin
#   @parametre $2      une chaîne
#   @parametre $3      'eq' ou 'le' ou 'ge' ou 'false'
#   @parametre $4      un nombre
#   @parametre $5      'f' ou 'd' ou 'false'
ls() {
    #Paramètres
    WHERE=$1/*
    PATTERN=$2
    SIGN=$3
    NOMBRE=$4
    TYPE=$5

    for I in $WHERE
    do
        #Appelle de la fonction 'type'
        I=$(type $I $TYPE)
        for FILE in $I
        do
            #Appelle de la fonction 'size'
            FILE=$(size $FILE $SIGN $NOMBRE)

            #Appelle de la fonction 'name'
            FILE=$(name $FILE $PATTERN)

            #Vérifie si '$FILE' est non vide
            if ! test -z $FILE 2>/dev/null  
            then
                #Affichage du resultat de la sélection
                echo $FILE #| tr " " "\n"
            fi
        done
    done
}
#Fonction gère l'option '-exe'
#   @parametre $1      fichier sélectionné
#   @parametre $2      une chaîne
exe() {
    #Paramètres
    WHERE=$(ls $WHERE $PATTERN $SIGN $NOMBRE $TYPE)
    BASE=$1

    for FILE in $WHERE
    do
        COMMAND=$BASE #pour pas modifier la commande entrée
        COMMAND=$(echo $COMMAND | sed -e "s@{}@$FILE@g") #remplace {} par le chemin du fichier
        eval $COMMAND
    done
}

#Initialisation des variables
SIGN=$(getsign $SIZE)
NOMBRE=$(getnombre $SIZE)

#Appele des fonctions
if test $COMMAND = "false"
then
#Afficher les fichiers sélectionnés
    ls $WHERE $PATTERN $SIGN $NOMBRE $TYPE
else
#Appliquer une commande aux fichiers trouvés
    exe $COMMAND
fi
