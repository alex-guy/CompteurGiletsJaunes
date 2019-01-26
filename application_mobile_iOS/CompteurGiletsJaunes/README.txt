/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Application "Compteur Gilets Jaunes"
====================================

L'objectif de cette application est de compter de manière fiable le nombre de
gilets jaunes au niveau national, ainsi que par région, département et commune.

Lors de l'inscription, l'application génére un identifiant unique (UUID) et
celui ci est stocké dans la KeyChain d'Apple. Même si on désinstalle et
reinstalle l'application, cette chaine est préservée.

Les données de location GPS (longitude et latitude) sont transmises avec cet
UUID à un serveur qui enregistre l'inscription (code source disponible).

Pour localiser la commune, l'application utilise les données Open Street Map.

L'application est diffusée en licence GPLv3 et le code source est disponible
sur GitHub, vous êtes invités à contribuer au projet !

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
