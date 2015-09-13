Projet Compilation 2015
=======================

![](tiger.jpg "Tigre qui Marche -- Antoine-Louis Barye")

Pablo Oliveira <pablo.oliveira@uvsq.fr>

Ce document décrit l'objectif, l'organisation et la notation du projet de
compilation.

Une version PDF de ce document est disponible à l'adresse
<http://tahiti.prism.uvsq.fr/compil/Projet.pdf>.

## Organisation du projet
### Constitution des Groupes

Merci de vous constituer en groupes de 4 personnes et d'envoyer un mail sur la
liste iatic4-compil avec la liste des membres du groupe avant le mercredi 17
mars.

* Groupe 1: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil1

* Groupe 2: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil2

* Groupe 3: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil3

* Groupe 4: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil4

* Groupe 5: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil5

* Groupe 6: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil6

* Groupe 7: git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil7

### Rendu

Le projet est à rendre avant le mercredi 6 mai à 13:00.  Le rendu du projet se
fait à travers des dépôt gits sur `tahiti.prism.uvsq.fr`.  Chaque groupe
possède un dépôt git propre nommé `compilX` où `X` est le numéro de groupe.

Les dépôts gits s'utilisent comme dans le module Système. Le groupe 1 par exemple,
utilisera la commande suivante pour cloner son dépôt:

```bash
git clone ssh://gitolite@tahiti.prism.uvsq.fr/compil1
```

### Questions

Les questions sont encouragées sur le groupe de discussion
<https://groups.google.com/group/iatic4-compil/> Les questions sont fortement
encouragées. J'essayerai de lire les messages et répondre à vos questions
régulièrement. Mais la participation de tous est encouragée: n'hésitez pas à
répondre aux questions de vos camarades, c'est le meilleur moyen d'apprendre!

### Plagiat
Si vous empruntez du code il faut:

   1. Citer sa provenance

   2. S'assurer que la licence du code vous permet de l'employer

Vous pouvez discuter et collaborer entre groupes, mais il est strictement
interdit de copier du code entre groupes.

Il est interdit de publier votre code.

Je vous invite à consulter les règles concernant le Plagiat de l'ISTY et de l'UVSQ:
<http://www.isty.uvsq.fr/medias/fichier/guide-anti-plagiat-et-charte_1311241484856.pdf>

## Objectif

L'objectif du projet de compilation est d'écrire la phase de traduction en
langage Intermédiaire (IR) expliquée en cours.  Pour rappel, la grammaire de la
représentation intermédiaire (IR) est donnée ci-dessous,

On distingue les Expressions (Exp) et les Effets (Stm)

~~~
IrNode ::= Exp
         | Stm
~~~

Les Expressions (Exp) peuvent être évaluées et produisent une donnée

~~~
Exp ::=
# constante entière
        "const" int

# étiquette
      | "name" label

# temporaire
      | "temp" temp

# un opérateur binaire, op est une chaîne parmis "(+)", "(-)", "(*)", "(/)"
      | "binop" op
            Exp
            Exp

# un accès mémoire à l'adresse donnée par Exp
      | "mem"
            Exp

# un appel à fonction. Normalement le premier Exp est de type Name et donne le
# nom de la fonction. Les Exp suivants correspondent aux arguments.
      | "call"
            Exp
            [{Exp}]
        "call end"

# un Eseq permet de combiner un Effet (Stm) et une Expression (Exp)
      | "eseq"
            Stm
            Exp
~~~

Les Effets (Stm) n'ont pas une valeur associée

~~~
Stm ::=
# Move déplace le deuxième Exp dans le premier Exp
# selon la nature du premier Exp on peut soit écrire dans un temporaire soit
# dans la mémoire
        "move"
            Exp
            Exp

# Sxp permet d'encapsuler une expression dans un Effet
      | "sxp"
            Exp

# Jump saute inconditionnellement à l'étiquette dans Exp (souvent de type Name)
      | "jump"
            Exp

# CJump saute vers le Name1 si "Exp1 relop Exp2" est vrai, sinon il
# saute vers Name2. relop est une chaîne parmi
# "(=)", "(<>)", "(<)", "(>)", "(<=)", "(>=)" et
      | "cjump" relop
            Exp1
            Exp2
            Name1
            Name2

# Seq encapsule une suite de Stm
      | "seq"
            [{Stm}]

# Label marque un point dans un programme.
      | "label"
            label
~~~

Votre projet doit prendre en entrée du code Tiger et produire sur la sortie
standard un programme en langage IR.

Par exemple le programme Tiger suivant
`print_int(21*2)` pourrait être traduit vers le code IR suivant:

~~~bash
call
  name print_int
      binop (*)
        const 21
        const 2
call end
~~~

En pratique les choses sont un peu plus compliquées, car chaque
fonction (et en particulier la fonction main) doivent avoir un
prologue et un épilogue.

Voici une traduction complète du programme Tiger `print_int(21*2)`.

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

Analysons la sortie en détail,

~~~bash
seq
  # Ce premier bloc d'Effets constitue le prologue

  # On déclare l'entrée du programme avec le label "main"
  label main

  # On sauve l'ancien pointeur de frame dans un temporaire
  move
    temp x1
    temp fp

  # On initialise une nouvelle frame en haut de la pile
  move
    temp fp
    temp sp

  # On réserve 4 octets en haut de la pile
  move
    temp sp
    binop (-)
      temp sp
      const 4

  # On stocke le premier argument (static link) dans l'espace ainsi crée
  # en haut de la pile
  move
    mem
      temp fp
    temp i0

  # On déplace dans le registre résultat la valeur 0.
  # (voir dernière ligne de l'eseq) Main doit toujours retourner 0.

  move
    temp rv
    eseq
      sxp
        # On appelle la primitive print_int avec 2*21 comme argument
        call
          name print_int
          # On lui passe comme premier argument 2 * 21
          binop (*)
            const 21
            const 2
        call end

      const 0

  # Maintenant vient l'épilogue
  # On remets le pointeur de pile là où il était originellement
  # à l'entrée de la fonction
  move
    temp sp
    temp fp

  # On restaure l'ancien pointeur de frame
  move
    temp fp
    temp x1
  label end
seq end
~~~

Bien entendu, un projet se construit petit à petit. Il ne faut
pas essayer de produire tout en même temps, mais procéder par petites
étapes validées par des tests.

Voici l'ordre d'implémentation conseillé:

1. Implémentez un ensemble de classes Java pour représenter le langage IR.
   Vous pouvez vous inspirer du code dans le paquet `jtiger.ast` et créer
   une nouvelle hiérarchie de noeuds dans le paquet `jtiger.ir`.

2. Créez un visiteur d'IR et utilisez le pour écrire une classe qui imprime sur
   la sortie standard un arbre IR. Testez votre "imprimeur" sur des petits
   arbres IR construits à la main.

3. Commencez à implémenter la traduction. Partez du cas le plus simple, la traduction d'un BinOp en IR.
   Prennez l'AST suivant par exemple:

~~~
        OpExp (+)
            IntegerExp(4)
            IntegerExp(2)
~~~

   Je vous conseille de traduire l'arbre en utilisant un visiteur d'AST. Le
   visiteur va traduire chaque feuille en noeuds IR `const 4` et `const 2`.  Puis
   le visiteur va traduire le noeud `OpExp` en noeud IR `binop`, en récupérant les
   traductions des feuilles. Finalement, l'arbre IR suivant sera produit:

~~~bash
    binop (+)
        const 4
        const 2
~~~

4. Faites une gestion très simple des FuncDec de manière à produire pour chaque fonction le prologue, la traduction du body, l'épilogue.
   Ce n'est pas la peine à ce stade de gérer les frames parfaitement.

5. Ecrivez la traduction des expresssions conditionelles sans variables (ex: `if (5 > 4) then 1 else 0`)

6. Implémentez l'appel des fonctions et testez des programmes simples.

7. Implémentez la gestion des frames.

8. Implémentez la gestion des variables.

9. Faites le reste (tableaux, chaînes, records, etc.)

### Code Fourni

Toutes les phases du compilateur vues en TP vous sont fournies: du lexeur
jusqu'à la vérification des types. Le code qui vous est fourni à l'adresse
<http://tahiti.prism.uvsq.fr/compil/livrable-projet.zip> prends
en entrée du code Tiger et produit un AST décoré avec les informations de bind.
L'AST est stocké après la phase de Type checking dans l'attribut ``ast`` de la
classe ``jtiger.cli.Control``.

## Comment tester votre projet

Pour tester votre projet, vous pouvez utiliser le simulateur IRVM 0.0.2.
Pour installer IRVM suivez les instructions ci-dessous:

~~~bash
$ wget http://tahiti.prism.uvsq.fr/compil/irvm-0.0.2.tar.gz
$ tar xjf irvm-0.0.2.tar.gz
$ cd irvm-0.0.2/
$ ./configure
$ make
$ sudo make install
~~~

Si tout se passe bien vous devez pouvoir executer,

~~~bash
$ irvm
Usage: irvm [OPTIONS] INPUT-FILE
--trace|-t    trace execution
--help|-h     print this help message
--version|-V  print version and exit
~~~

IRVM est un simulateur open-source pour la représentation intermédiaire IR.
La documentation est disponible à l'adresse
<http://tahiti.prism.uvsq.fr/compil/irvm.html>.

IRVM permet de simuler l'exécution de code IR. Par exemple,

~~~bash
$ echo "print_int(21*2)" > test1.tig
$ java jtiger.cli.Compile -h test1.tig > test1.ir
$ irvm test1.ir
42
~~~

IRVM possède un mode trace, vous permettant de debugger vos programmes:

~~~bash
$ irvm --trace test1.ir

2.2-2.6: label main
5.4-5.7: temp fp = 16383
3.2-3.5: move temp x1 16383
8.4-8.7: temp sp = 16383
6.2-6.5: move temp fp 16383
12.6-12.9: temp sp = 16383
13.6-13.10: const 4
11.4-11.8: binop (-) 16383 4 = 16379
9.2-9.5: move temp sp 16379
17.4-17.7: temp i0 = 0
16.6-16.9: temp fp = 16383
14.2-14.5: move mem [16383] 0
25.12-25.16: const 21
26.12-26.16: const 2
24.10-24.14: binop (*) 21 2 = 42
22.8-22.11: call print_int
22.8-22.11:     i0 = 42
22.8-22.11: call end print_int = 0
28.6-28.10: const 0
20.4-20.7: eseq = 0
18.2-18.5: move temp rv 0
31.4-31.7: temp fp = 16383
29.2-29.5: move temp sp 16383
34.4-34.7: temp x1 = 16383
32.2-32.5: move temp fp 16383
35.2-35.6: end of program
~~~

Comme vous avez du le remarquer certains noms de temporaires sont réservés dans IRVM:

* `rv` pour la valeur de retour
* `sp` et `fp` pour le stack pointer et frame pointer
* `i0` `i1` ... `i<n>` pour les paramètres passés en argument (consultez la documentation sur <http://tahiti.prism.uvsq.fr/compil/irvm.html#Special-Temporaries>)

## Documentation et Rapport

Le code produit sera commenté et indenté en utilisant un style uniforme.
Les commentaires seront en anglais.

Un fichier README sera commité à la racine du projet. Il détaillera ce qui
est implémenté, ce qui marche et ce qui ne marche pas.

De plus, chaque groupe produira un rapport au format PDF détaillant le travail
fait et décrivant les choix d'implémentation. Le rapport PDF sera commité à la
racine du projet également et aura pour nom `Rapport.pdf`.  La charte
anti-plagiat de l'UVSQ *doit être inclue en fin du rapport*.  Le rapport
comportera 15 pages au maximum (sans tenir compte de la charte anti-plagiat et
des éventuels annexes).

Enfin, chaque membre du groupe devra compléter le formulaire disponible à l'adresse
<http://tahiti.prism.uvsq.fr/compil/formulaire.txt>

Une fois complété, chaque membre du groupe:

 1. Le renommera sous le nom `'formulaire-nom.txt'` où nom sera remplacé
    par son nom de famille.

 2. Me le renverra par mail (avant la date limite de rendu) à l'adresse <pablo.oliveira@uvsq.fr>.
 Le mail portera comme sujet "[COMPIL] Formulaire groupe X" où X est le numéro
 de votre groupe.

## Tests

Chaque groupe devra produire un ensemble de tests qui valident le traducteur implémenté.
Les tests seront commités dans un répertoire `tests/` à la racine du projet.
Pour chaque test vous devez inclure trois fichiers:

* le programme Tiger (``test???.tig``)
* la sortie IR attendue (``test???.ir``)
* la sortie IRVM attendue (``test???.exp``)

## Comment sera noté votre projet

Le barème est le suivant:

* Qualité du code: **4 points**
    * code bien commenté et structuré
    * projet rendu avec un ensemble de tests (au minimum 20 par groupe)
    * projet rendu avec un README qui détaille ce qui est implémenté
* Correction du code: **8 points**
* Qualité de la traduction:  **2 points**
    * Est-ce que les optimizations décrites en cours pour la traduction des expressions conditionnelles ont été implémentées.
    * Est-ce que d'autres optimizations ont été implémentées (par exemple Constant Folding ?)
* Rapport: **6 points**

* Contribution individuelle: les [formulaires
  individuels](http://tahiti.prism.uvsq.fr/compil/formulaire.txt) permettront
  de déterminer pour chaque membre du groupe un malus/bonus allant de **-20** à
  **+20** qui viendra s'ajouter au barème ci-dessus.

La correction du code sera évaluée par un script de manière automatique. Attention assurez vous que les étapes suivantes marchent pour votre rendu.
Si votre projet nécessite une intervention manuelle de ma part car vous n'avez pas respecté les consignes, vous serez pénalisés.

~~~bash
$ ant clean
$ ant
$ java jtiger.cli.Compile -h ../secret-tests/test001. > ../secret-tests/test001.ir
$ irvm ../secret-tests/test001.ir > ../secret-tests/test001.out
~~~

Votre projet sera compilé et exécuté sur un ensemble de 140 tests. Votre
note sera calculée avec la formule suivante: ``nombre de tests passés/140*8``.

Attention votre projet sera exécuté avec la commande ``java jtiger.cli.Compile -h <entree.tig>``.
La sortie doit être du code IR légal que IRVM peut executer.

Si vous avez tout fini avant la date de rendu et vous souhaitez aller plus loin
dans le compilateur, envoyez moi un mail.

## Exemples de traductions

### Chaînes
```bash
let
   var a : string := "hello"
in
  print(a)
end

=>

label _L29
"hello"
seq
  label main
  move
    temp x2
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
      seq
        move
          temp x1
          name _L29
        sxp
          call
            name print
            temp x1
          call end
      seq end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x2
  label end
seq end
```

### Tableaux

```bash
let
  type  intarr = array of int
  var arr : intarr := intarr [10] of 0
in
  print_int(arr[2])
end

=>

seq
  label main
  move
    temp x2
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
      seq
        move
          temp x1
          call
            name init_array
            const 10
            const 0
          call end
        sxp
          call
            name print_int
            mem
              binop (+)
                temp x1
                binop (*)
                  const 2
                  const 4
          call end
      seq end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x2
  label end
seq end
```

### Records

```bash
let
  type personne = {name:string, age:int}
  var a : personne := personne {name="Marvin", age=20}
in
  a.age := a.age + 1
end

=>

label _L29
"Marvin"
seq
  label main
  move
    temp x3
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
      seq
        move
          temp x1
          eseq
            seq
              move
                temp x2
                call
                  name malloc
                  const 8
                call end
              move
                mem
                  binop (+)
                    temp x2
                    const 0
                name _L29
              move
                mem
                  binop (+)
                    temp x2
                    const 4
                const 20
            seq end
            temp x2
        move
          mem
            binop (+)
              temp x1
              binop (*)
                const 1
                const 4
          binop (+)
            mem
              binop (+)
                temp x1
                binop (*)
                  const 1
                  const 4
            const 1
      seq end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x3
  label end
seq end
```

### Factorielle

```bash
let
  function fact(n:int) : int =
    if 1 < n then n * fact(n-1) else 1
in
    print_int(fact(7))
end

=>

seq
  label _L2fact
  move
    temp x3
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
    temp x1
    temp i1
  move
    temp rv
    eseq
      seq
        cjump (<)
          const 1
          temp x1
         name _L32 name _L33
        label _L33
        move
          temp x2
          const 1
        jump
          name _L31
        label _L32
        move
          temp x2
          binop (*)
            temp x1
            call
              name _L2fact
              mem
                temp fp
              binop (-)
                temp x1
                const 1
            call end
        label _L31
      seq end
      temp x2
  move
    temp sp
    temp fp
  move
    temp fp
    temp x3
  label end
seq end
seq
  label main
  move
    temp x4
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
          call
            name _L2fact
            temp fp
            const 7
          call end
        call end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x4
  label end
seq end
```

### Variable qui échappe

```bash
let
    var a := 0 /* la variable a echappe */
    function plusUn() : int = a + 1
in
    print_int(plusUn())
end

=>

seq
  label _L2plusUn
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
    binop (+)
      mem
        binop (+)
          mem
            temp fp
          const -4
      const 1
  move
    temp sp
    temp fp
  move
    temp fp
    temp x1
  label end
seq end

seq
  label main
  move
    temp x2
    temp fp
  move
    temp fp
    temp sp
  move
    temp sp
    binop (-)
      temp sp
      const 8
  move
    mem
      temp fp
    temp i0
  move
    temp rv
    eseq
      seq
        move
          mem
            binop (+)
              temp fp
              const -4
          const 0
        sxp
          call
            name print_int
            call
              name _L2plusUn
              temp fp
            call end
          call end
      seq end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x2
  label end
seq end
```


### Tri Fusion (Merge Sort)

Ce programme est un tri Fusion qui permets de trier une liste avec une
complexité de $O(n.log(n))$. Il a été écrit par Andrew Appel créateur du langage Tiger.

Pour passer ce programme votre compilateur devra avoir implémenté pratiquement
tout Tiger.

```bash
let
 type any = {any : int}
 var buffer := getchar ()

 function readint (any : any) : int =
   let var i := 0
       function isdigit (s : string) : int =
	 ord ("0") <= ord (s) & ord (s) <= ord ("9")
       function skipto () =
   	 while buffer = " " | buffer = "\n"
   	   do buffer := getchar ()
   in skipto ();
      any.any := isdigit (buffer);
      while isdigit (buffer)
   	do (i := i * 10 + ord (buffer) - ord ("0");
	    buffer := getchar ());
      i
   end

 type list = {first : int, rest : list}

 function readlist () : list =
   let var any := any{any=0}
       var i := readint (any)
   in if any.any
	then list{first=i,rest=readlist ()}
	else nil
   end

 function merge (a : list, b : list) : list =
   if a = nil then b
   else if b = nil then a
   else if a.first < b.first
      then list {first = a.first, rest = merge (a.rest, b)}
      else list {first = b.first, rest = merge (a, b.rest)}

 function printmint (i : int) =
   let function f (i : int) =
	if i > 0
	then (f (i/10); print (chr (i-i/10*10+ord ("0"))))
   in if i < 0 then (print ("-"); f (-i))
      else if i>0 then f (i)
      else print ("0")
   end

 function printlist (l : list) =
   if l = nil then print ("\n")
   else (printmint (l.first); print (" "); printlist (l.rest))

   var list1 := readlist ()
   var list2 := (buffer := getchar (); readlist ())

in printlist (merge (list1,list2))
end

=>

label _L46
"\071"
label _L45
"\060"
seq
  label _L2isdigit
  move
    temp x6
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
    temp x3
    temp i1
  move
    temp rv
    eseq
      seq
        cjump (<=)
          call
            name ord
            name _L45
          call end
          call
            name ord
            temp x3
          call end
         name _L50 name _L51
        label _L51
        move
          temp x4
          const 0
        jump
          name _L49
        label _L50
        move
          temp x4
          eseq
            seq
              move
                temp x5
                const 1
              cjump (<=)
                call
                  name ord
                  temp x3
                call end
                call
                  name ord
                  name _L46
                call end
               name _L47 name _L48
              label _L48
              move
                temp x5
                const 0
              label _L47
            seq end
            temp x5
        label _L49
      seq end
      temp x4
  move
    temp sp
    temp fp
  move
    temp fp
    temp x6
  label end
seq end
label _L55
"\040"
label _L56
"\012"
seq
  label _L4skipto
  move
    temp x7
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
  seq
    label _L52
    seq
      cjump (=)
        call
          name strcmp
          mem
            binop (+)
              mem
                mem
                  temp fp
              const -4
          name _L55
        call end
        const 0
       name _L58 name _L59
      label _L59
      cjump (=)
        call
          name strcmp
          mem
            binop (+)
              mem
                mem
                  temp fp
              const -4
          name _L56
        call end
        const 0
       name _L53 name _L54
      jump
        name _L57
      label _L58
      jump
        name _L53
      label _L57
    seq end
    label _L53
    move
      mem
        binop (+)
          mem
            mem
              temp fp
          const -4
      call
        name getchar
      call end
    jump
      name _L52
    label _L54
  seq end
  move
    temp sp
    temp fp
  move
    temp fp
    temp x7
  label end
seq end
label _L63
"\060"
seq
  label _L6readint
  move
    temp x8
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
    temp x1
    temp i1
  move
    temp rv
    eseq
      move
        temp x2
        const 0
      eseq
        seq
          sxp
            call
              name _L4skipto
              temp fp
            call end
          move
            mem
              binop (+)
                temp x1
                binop (*)
                  const 0
                  const 4
            call
              name _L2isdigit
              temp fp
              mem
                binop (+)
                  mem
                    temp fp
                  const -4
            call end
          seq
            label _L60
            cjump (<>)
              call
                name _L2isdigit
                temp fp
                mem
                  binop (+)
                    mem
                      temp fp
                    const -4
              call end
              const 0
             name _L61 name _L62
            label _L61
            seq
              move
                temp x2
                binop (-)
                  binop (+)
                    binop (*)
                      temp x2
                      const 10
                    call
                      name ord
                      mem
                        binop (+)
                          mem
                            temp fp
                          const -4
                    call end
                  call
                    name ord
                    name _L63
                  call end
              move
                mem
                  binop (+)
                    mem
                      temp fp
                    const -4
                call
                  name getchar
                call end
            seq end
            jump
              name _L60
            label _L62
          seq end
        seq end
        temp x2
  move
    temp sp
    temp fp
  move
    temp fp
    temp x8
  label end
seq end
seq
  label _L8readlist
  move
    temp x14
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
      seq
        move
          temp x9
          eseq
            seq
              move
                temp x10
                call
                  name malloc
                  const 4
                call end
              move
                mem
                  binop (+)
                    temp x10
                    const 0
                const 0
            seq end
            temp x10
        move
          temp x11
          call
            name _L6readint
            mem
              temp fp
            temp x9
          call end
      seq end
      eseq
        seq
          cjump (<>)
            mem
              binop (+)
                temp x9
                binop (*)
                  const 0
                  const 4
            const 0
           name _L65 name _L66
          label _L66
          move
            temp x13
            const 0
          jump
            name _L64
          label _L65
          move
            temp x13
            eseq
              seq
                move
                  temp x12
                  call
                    name malloc
                    const 8
                  call end
                move
                  mem
                    binop (+)
                      temp x12
                      const 0
                  temp x11
                move
                  mem
                    binop (+)
                      temp x12
                      const 4
                  call
                    name _L8readlist
                    mem
                      temp fp
                  call end
              seq end
              temp x12
          label _L64
        seq end
        temp x13
  move
    temp sp
    temp fp
  move
    temp fp
    temp x14
  label end
seq end
seq
  label _L10merge
  move
    temp x22
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
    temp x15
    temp i1
  move
    temp x16
    temp i2
  move
    temp rv
    eseq
      seq
        cjump (=)
          temp x15
          const 0
         name _L74 name _L75
        label _L75
        move
          temp x19
          eseq
            seq
              cjump (=)
                temp x16
                const 0
               name _L71 name _L72
              label _L72
              move
                temp x20
                eseq
                  seq
                    cjump (<)
                      mem
                        binop (+)
                          temp x15
                          binop (*)
                            const 0
                            const 4
                      mem
                        binop (+)
                          temp x16
                          binop (*)
                            const 0
                            const 4
                     name _L68 name _L69
                    label _L69
                    move
                      temp x21
                      eseq
                        seq
                          move
                            temp x18
                            call
                              name malloc
                              const 8
                            call end
                          move
                            mem
                              binop (+)
                                temp x18
                                const 0
                            mem
                              binop (+)
                                temp x16
                                binop (*)
                                  const 0
                                  const 4
                          move
                            mem
                              binop (+)
                                temp x18
                                const 4
                            call
                              name _L10merge
                              mem
                                temp fp
                              temp x15
                              mem
                                binop (+)
                                  temp x16
                                  binop (*)
                                    const 1
                                    const 4
                            call end
                        seq end
                        temp x18
                    jump
                      name _L67
                    label _L68
                    move
                      temp x21
                      eseq
                        seq
                          move
                            temp x17
                            call
                              name malloc
                              const 8
                            call end
                          move
                            mem
                              binop (+)
                                temp x17
                                const 0
                            mem
                              binop (+)
                                temp x15
                                binop (*)
                                  const 0
                                  const 4
                          move
                            mem
                              binop (+)
                                temp x17
                                const 4
                            call
                              name _L10merge
                              mem
                                temp fp
                              mem
                                binop (+)
                                  temp x15
                                  binop (*)
                                    const 1
                                    const 4
                              temp x16
                            call end
                        seq end
                        temp x17
                    label _L67
                  seq end
                  temp x21
              jump
                name _L70
              label _L71
              move
                temp x20
                temp x15
              label _L70
            seq end
            temp x20
        jump
          name _L73
        label _L74
        move
          temp x19
          temp x16
        label _L73
      seq end
      temp x19
  move
    temp sp
    temp fp
  move
    temp fp
    temp x22
  label end
seq end
label _L76
"\060"
seq
  label _L12f
  move
    temp x25
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
    temp x24
    temp i1
  seq
    cjump (>)
      temp x24
      const 0
     name _L78 name _L77
    label _L78
    seq
      sxp
        call
          name _L12f
          mem
            temp fp
          binop (/)
            temp x24
            const 10
        call end
      sxp
        call
          name print
          call
            name chr
            binop (+)
              binop (-)
                temp x24
                binop (*)
                  binop (/)
                    temp x24
                    const 10
                  const 10
              call
                name ord
                name _L76
              call end
          call end
        call end
    seq end
    label _L77
  seq end
  move
    temp sp
    temp fp
  move
    temp fp
    temp x25
  label end
seq end
label _L80
"\060"
label _L79
"\055"
seq
  label _L14printmint
  move
    temp x26
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
    temp x23
    temp i1
  seq
    cjump (<)
      temp x23
      const 0
     name _L85 name _L86
    label _L86
    seq
      cjump (>)
        temp x23
        const 0
       name _L82 name _L83
      label _L83
      sxp
        call
          name print
          name _L80
        call end
      jump
        name _L81
      label _L82
      sxp
        call
          name _L12f
          temp fp
          temp x23
        call end
      label _L81
    seq end
    jump
      name _L84
    label _L85
    seq
      sxp
        call
          name print
          name _L79
        call end
      sxp
        call
          name _L12f
          temp fp
          binop (-)
            const 0
            temp x23
        call end
    seq end
    label _L84
  seq end
  move
    temp sp
    temp fp
  move
    temp fp
    temp x26
  label end
seq end
label _L87
"\012"
label _L88
"\040"
seq
  label _L16printlist
  move
    temp x28
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
    temp x27
    temp i1
  seq
    cjump (=)
      temp x27
      const 0
     name _L90 name _L91
    label _L91
    seq
      sxp
        call
          name _L14printmint
          mem
            temp fp
          mem
            binop (+)
              temp x27
              binop (*)
                const 0
                const 4
        call end
      sxp
        call
          name print
          name _L88
        call end
      sxp
        call
          name _L16printlist
          mem
            temp fp
          mem
            binop (+)
              temp x27
              binop (*)
                const 1
                const 4
        call end
    seq end
    jump
      name _L89
    label _L90
    sxp
      call
        name print
        name _L87
      call end
    label _L89
  seq end
  move
    temp sp
    temp fp
  move
    temp fp
    temp x28
  label end
seq end
seq
  label main
  move
    temp x31
    temp fp
  move
    temp fp
    temp sp
  move
    temp sp
    binop (-)
      temp sp
      const 8
  move
    mem
      temp fp
    temp i0
  move
    temp rv
    eseq
      seq
        move
          mem
            binop (+)
              temp fp
              const -4
          call
            name getchar
          call end
        move
          temp x29
          call
            name _L8readlist
            temp fp
          call end
        move
          temp x30
          eseq
            move
              mem
                binop (+)
                  temp fp
                  const -4
              call
                name getchar
              call end
            call
              name _L8readlist
              temp fp
            call end
        sxp
          call
            name _L16printlist
            temp fp
            call
              name _L10merge
              temp fp
              temp x29
              temp x30
            call end
          call end
      seq end
      const 0
  move
    temp sp
    temp fp
  move
    temp fp
    temp x31
  label end
seq end
```
