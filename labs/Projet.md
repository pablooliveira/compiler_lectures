Projet Compilation
==================

## Règles
### Rendu
Le projet est à rendre avant le mercredi 24 avril à 23h59.
Pour rendre le projet envoyer une archive qui respecte
la nomenclature ``nom1-nom2-projet-compil-13.tar.gz``
à l'adresse <pablo.oliveira@prism.uvsq.fr>. Le sujet
du mail sera "[COMPIL] Rendu Projet nom1 nom2".
(Si les consignes de rendu ne sont pas respectées, 
votre note projet sera minorée d'un point).

Un projet rendu en retard aura la note éliminatoire de 0/20.

### Questions

Les questions sont encouragées sur le site <https://piazza.com/#spring2013/ini2compilation/>.

### Plagiat
Si vous empruntez du code il faut:

   1. Citer sa provenance

   2. S'assurer que la licence du code vous permet de l'employer

Vous pouvez discuter et collaborer entre groupes, mais il est strictement
interdit de copier du code entre groupes.

Il est interdit de publier votre code.

Si vous ne respectez pas ces règles, votre note projet sera de 0/20.

## Objectif

L'objectif du projet de compilation est d'écrire la phase de traduction en
langage Intermédiaire. Toutes les phases du compilateur vues en TP vous sont
fournies: du lexeur jusqu'à la vérification des types. Le code qui vous est
fourni à l'adresse
<http://tahiti.prism.uvsq.fr/jtiger/static/support/livrable-projet.zip> prends
en entrée du code Tiger et produit un AST décoré avec les informations de
bind.  L'AST est stocké après la phase de Type checking dans l'attribut
``ast`` de la classe ``jtiger.cli.Control``.

Vous devez implémenter la traduction en langage intermédiaire qui a été
expliquée en cours.
Pour rappel, la grammaire de la représentation intermédiaire (IR) est donnée
ci-dessous,

~~~
Sxp ::= "const" int
      | "name" Label
      | "temp" Temp
      | "binop" Oper Sxp Sxp
      | "mem" Sxp
      | "call" Sxp [{Sxp}]
      | "eseq" Stm Sxp

Stm ::= "Move" Sxp Sxp
      | "sxp" Sxp
      | "jump" Sxp [{Label}]
      | "cjump" Relop Exp Exp Label Label
      | "seq" [{Stm}]
      | "label" Label
Oper ::= "+" | "-" | "*" | "/"
Relop ::= "=" | "<>" | "<=" | ">=" | "<" | ">"
~~~

Votre projet doit prendre en entrée du code Tiger et produire sur la sortie standard la représentation intermédiaire.

\pagebreak

Voici un exemple,

~~~bash
$ echo "print_int(21*2)" > test1.tig 
$ java jtiger.cli.Compile -h test1.tig > test1.ir
$ cat test1.ir
seq
  label main
  move
    temp x1
    temp fp
  move
    temp fp
    temp sp
  move
    temp sp
    binop (-)
      temp sp
      const 4
  move
    mem
      temp fp
    temp i0
  move
    temp rv
    eseq
      sxp
        call
          name print_int
          binop (*)
            const 21
            const 2
        call end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x1
  label end
seq end
~~~

## Comment tester votre projet

Pour tester votre projet, vous pouvez utiliser le simulateur HAVM 0.25.
Pour installer HAVM suivez les instructions ci-dessous:

~~~bash
$ sudo apt-get install happy ghc
$ wget http://tahiti.prism.uvsq.fr/jtiger/static/support/havm-0.25.tar.bz2
$ tar xjf havm-0.25.tar.bz2
$ cd havm-0.25/
$ ./configure
$ make 
$ sudo make install 
~~~

Si tout se passe bien vous devez pouvoir executer,

~~~bash
$ havm 
Usage: havm [OPTIONS] INPUT-FILE
~~~

HAVM est un simulateur open-source pour la représentation intermédiaire Tiger maintenu
par l'équipe du LRDE à l'Epita. La documentation est disponible à l'adresse
<http://www.lrde.epita.fr/~akim/ccmp/doc/havm.html>.

HAVM permet de simuler l'exécution de code IR. Par exemple,

~~~bash
$ echo "print_int(21*2)" > test1.tig 
$ java jtiger.cli.Compile -h test1.tig > test1.ir
$ havm test1.ir
42
~~~ 

## Comment sera noté votre projet

Le barème est le suivant:

* Qualité du code: **5 points**
    * code bien commenté et structuré
    * projet rendu avec un ensemble de tests (au minimum 20 par groupe)
    * projet rendu avec un README qui détaille ce qui est implémenté
* Soutenance : **5 points**
* Correction du code: **8 points**
* Qualité de la traduction:  **2 points**
    * Est-ce que les optimizations décrites en cours pour la traduction des expressions conditionnelles ont été implémentées.
    * Est-ce que d'autres optimizations ont été implémentées (par exemple Constant Folding ?)


La correction du code sera évaluée par un script de manière automatique. Attention assurez vous que les étapes suivantes marchent pour votre rendu.
Si votre projet nécessite une intervention manuelle de ma part car vous n'avez pas respecté les consignes, vous serez pénalisés. 

~~~bash
$ tar xvf nom1-nom2-projet-compil-13.tar.gz
$ cd nom1-nom2-projet-compil-13/
$ ant clean
$ ant
$ java jtiger.cli.Compile -h ../secret-tests/test001.tig > ../secret-tests/test001.ir
$ havm ../secret-tests/test001.ir > ../secret-tests/test001.output
$ diff ../secret-tests/test001.output ../secret-tests/test001.expected
~~~


Votre projet sera compilé et exécuté sur un ensemble de 140 tests. Votre
note sera calculée avec la formule suivante: ``nombre de tests passés/140*8``.

Attention votre projet sera exécuté avec la commande ``java jtiger.cli.Compile -h <entree.tig>``.
La sortie doit être du code IR légal que HAVM peut executer.

Les tests ne vous seront pas fournis cette fois ci. C'est à vous d'en écrire
durant le développement du projet. Les tests doivent être inclus dans l'archive de rendu de projet
dans le répertoire ``tests/``. Pour chaque test vous devez inclure trois fichiers:

* le programme tiger (``test???.tig``)
* la sortie IR attendue (``test???.ir``)
* la sortie HAVM attendue (``test???.expected``)

## Bonus

Si vous avez tout fini avant la date de rendu et vous souhaitez aller plus loin
dans le compilateur, envoyez moi un mail.
