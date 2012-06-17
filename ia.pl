get([T|_],I,X) :- I = 1, !, X = T.
get([_|Q],I,X) :- J is I - 1, get(Q,J,X).


%element(X, [T|_]) :- X = T.
%element(X, [_|Q]) :- element(X,Q).
element(X,L):- member(X,L).


% Remplace l'élément Prev d'une liste par l'élément New
sed([Prev|L],Prev,New,[New|L]) :- !.
sed([X|L],Prev,New,[X|NewL]) :- sed(L,Prev,New,NewL).


plateauDepart(Plateau) :- Plateau = [[(0,0),(0,0),(0,0),(0,0),(0,0)],[(0,0),(0,0),(0,0),(0,0),(0,0)], [32,33,34],'E'].


%plateauTest(Plateau) :- Plateau = [[(13,'N'),(33,'S'),(43,'N'),(0,0),(0,0)],[(0,0),(0,0),(0,0),(0,0),(0,0)],[23,42,34],'E'].
plateauTest(Plateau) :- Plateau = [[(11,'N'),(21,'S'),(32,'W'),(14,'S'),(12,'W')],[(55,'W'),(23,'S'),(31,'E'),(22,'N'),(42,'N')],[33,52,34],'R'].


affiche_direction(Dir,O) :- O = Dir, Dir = 'W', !, write(' < ').
affiche_direction(Dir,O) :- O = Dir, Dir = 'E', !, write(' > ').
affiche_direction(_,O) :- O = 'N', !, write(' ^ ').
affiche_direction(_,O) :- O = 'S', !, write(' v ').
affiche_direction(_,_) :- tab(3).


affiche_case([T|_],Case,Joueur) :- Joueur = 0, Y = (Case,O), element(Y,T), !, affiche_direction('W',O), write('E'), affiche_direction('E',O). % Affichage Elephant
affiche_case([T|_],Case,Joueur) :- Joueur = 1, Y = (Case,O), element(Y,T), !, affiche_direction('W',O), write('R'), affiche_direction('E',O). % Affichage Rino
affiche_case([T|_],Case,_) :- element(Case,T), !, tab(3), write('M'), tab(3). % Affichage montagne
affiche_case([_|Plateau],Case,Joueur) :- !, Z is Joueur + 1, affiche_case(Plateau, Case, Z).
affiche_case(_,_,_) :- tab(7).


affiche_ligne(Plateau,Ligne) :-
   write(Ligne), write('.'), write(' ||'), Case1 is Ligne * 10 + 1, affiche_case(Plateau,Case1,0),
   write('||'), Case2 is Ligne * 10 + 2, affiche_case(Plateau,Case2,0),
   write('||'), Case3 is Ligne * 10 + 3, affiche_case(Plateau,Case3,0),
   write('||'), Case4 is Ligne * 10 + 4, affiche_case(Plateau,Case4,0),
   write('||'), Case5 is Ligne * 10 + 5, affiche_case(Plateau,Case5,0),
   write('||'), nl.
affiche_plateau(Plateau) :-
   write('Tour de : '), get(Plateau,4,Joueur), write(Joueur),nl,
   tab(3), write('         .1   '), write('        .2   '), write('        .3   '), write('        .4   '), write('   .5         '), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl,
   tab(3), write('||'), tab(2), write('51'),tab(3), write('||'), tab(2), write('52'),tab(3), write('||'), tab(2), write('53'),tab(3), write('||'), tab(2), write('54'),tab(3), write('||'), tab(2), write('55'),tab(3), write('||'), nl,
   affiche_ligne(Plateau,5),
   tab(3), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl,
   tab(3), write('||'), tab(2), write('41'),tab(3), write('||'), tab(2), write('42'),tab(3), write('||'), tab(2), write('43'),tab(3), write('||'), tab(2), write('44'),tab(3), write('||'), tab(2), write('45'),tab(3), write('||'), nl,
   affiche_ligne(Plateau,4),
   tab(3), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl,
   tab(3), write('||'), tab(2), write('31'),tab(3), write('||'), tab(2), write('32'),tab(3), write('||'), tab(2), write('33'),tab(3), write('||'), tab(2), write('34'),tab(3), write('||'), tab(2), write('35'),tab(3), write('||'), nl,
   affiche_ligne(Plateau,3),
   tab(3), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl,
   tab(3), write('||'), tab(2), write('21'),tab(3), write('||'), tab(2), write('22'),tab(3), write('||'), tab(2), write('23'),tab(3), write('||'), tab(2), write('24'),tab(3), write('||'), tab(2), write('25'),tab(3), write('||'), nl,
   affiche_ligne(Plateau,2),
   tab(3), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl,
   tab(3), write('||'), tab(2), write('11'),tab(3), write('||'), tab(2), write('12'),tab(3), write('||'), tab(2), write('13'),tab(3), write('||'), tab(2), write('14'),tab(3), write('||'), tab(2), write('15'),tab(3), write('||'), nl,
   affiche_ligne(Plateau,1),
   tab(3), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), tab(7), write('||'), nl,
   tab(3), write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl.


isElephant([E,_,_,_],Case) :- element((Case,_),E), Case > 0.
isRhinoceros([_,R,_,_],Case) :- element((Case,_),R), Case > 0.
isMontagne([_,_,M,_],Case) :- element(Case,M), Case > 0.
tourJoueur([_,_,_,J],J).
dispoElephant([E,_,_,_]):- element((0,_),E), !.
dispoRhinoceros([_,R,_,_]):- element((0,_),R), !.
   
case_occupee(Plateau,Case,X):- isElephant(Plateau,Case), !, X = 'E'.
case_occupee(Plateau,Case,X):- isRhinoceros(Plateau,Case), !, X = 'R'.
case_occupee(Plateau,Case,X):- isMontagne(Plateau,Case), !, X = 'M'.




% on évalue les cases devant l’animal,
% la force +1 si un éléphant ou rhinocéros est dans  la meme direction,
% la masse +1 si un pion  dans la direction opposée ou une montagne.
% Si force > masse et force > 0, la poussée est possible, sinon impossible.


% affiche la direction d'une case peu importe s'il s'agit de E ou R
direction_case(_,0,_):- !.
direction_case([E,_,_,_],Case,Direction) :- element((Case,Direction),E), !.
direction_case([_,R,_,_],Case,Direction) :- element((Case,Direction),R), !.


borneCase(Case,CaseB):- Case > 55, !, CaseB = 0.
borneCase(Case,CaseB):- Case < 11, !, CaseB = 0.
borneCase(Case,CaseB):- Tmp is Case mod 10, Tmp = 0, !, CaseB = 0.
borneCase(Case,CaseB):- Tmp is Case mod 10, Tmp > 5, !, CaseB = 0.
borneCase(Case,Case).


caseSuiv(0,_,Case):- element(Case, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]).
caseSuiv(Case,Dir,CaseSuivB):- Dir = 'W', element(Case, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), CaseSuiv is Case - 1, borneCase(CaseSuiv,CaseSuivB).
caseSuiv(Case,Dir,CaseSuivB):- Dir = 'E', element(Case, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), CaseSuiv is Case + 1, borneCase(CaseSuiv,CaseSuivB).
caseSuiv(Case,Dir,CaseSuivB):- Dir = 'S', element(Case, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), CaseSuiv is Case - 10, borneCase(CaseSuiv,CaseSuivB).
caseSuiv(Case,Dir,CaseSuivB):- Dir = 'N', element(Case, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), CaseSuiv is Case + 10, borneCase(CaseSuiv,CaseSuivB).


dirOp('E','W').
dirOp('W','E').
dirOp('N','S').
dirOp('S','N').


comptageForceMasse(Plateau,Case,_,Force,Masse,Force,NewMasse):- isMontagne(Plateau,Case), !, NewMasse is Masse + 1.
comptageForceMasse(Plateau,Case,Dir,Force,Masse,NewForce,Masse):- direction_case(Plateau,Case,O), Dir = O, !, NewForce is Force + 1.
comptageForceMasse(Plateau,Case,Dir,Force,Masse,NewForce,Masse):- direction_case(Plateau,Case,O), dirOp(Dir,O), !, NewForce is Force - 1.
comptageForceMasse(_,_,_,Force,Masse,Force,Masse).


plusFort(Force,Masse):- Force > 0, Force >= Masse.


comptage(Plateau, Case, Dir, Force, Masse):- \+case_occupee(Plateau,Case,_), !.
comptage(Plateau, Case, Dir, Force, Masse):- comptageForceMasse(Plateau,Case, Dir, Force,Masse,NewForce,NewMasse),
                                                plusFort(NewForce,NewMasse), !, caseSuiv(Case,Dir,CaseSuiv), comptage(Plateau, CaseSuiv, Dir, NewForce, NewMasse).


poussee_possible(Plateau,(Depart,Arrivee,O)) :- direction_case(Plateau,Depart,O), caseSuiv(Depart,O,Arrivee),
                                                   comptage(Plateau,Arrivee,O,1,0).


verifDir(O):- element(O,['N','S','E','W']).
verifCoupEntree((_,Arrivee,O)):- verifDir(O), element(Arrivee, [11,12,13,14,15,21,25,31,35,41,45,51,52,53,54,55]).
verifCoup((Depart,Arrivee,O)):- element(Depart, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), element(Arrivee, [11,12,13,14,15,21,22,23,24,25,31,32,33,34,35,41,42,43,44,45,51,52,53,54,55]), verifDir(O).




% Controle que le joueur a une pièce à faire entrer
verifEntree(Plateau, 0):- tourJoueur(Plateau,J), J = 'E', dispoElephant(Plateau), !.
verifEntree(Plateau, 0):- tourJoueur(Plateau,J), J = 'R', dispoRhinoceros(Plateau), !.




verifOrientationPousseeEntree(Depart,_,_):- Depart \= 0, !.
verifOrientationPousseeEntree(0,Arrivee,'N'):- element(Arrivee, [11,12,13,14,15]).
verifOrientationPousseeEntree(0,Arrivee,'S'):- element(Arrivee, [51,52,53,54,55]).
verifOrientationPousseeEntree(0,Arrivee,'E'):- element(Arrivee, [51,41,31,21,11]).
verifOrientationPousseeEntree(0,Arrivee,'W'):- element(Arrivee, [15,25,35,45,55]).


% Traitement en fonction de la case de destination
verifCase(Plateau, (_,Arrivee,_)):- \+case_occupee(Plateau,Arrivee,_), !.
verifCase(Plateau, (Depart,Arrivee,O)):- verifOrientationPousseeEntree(Depart,Arrivee,O), poussee_possible(Plateau,(Depart,Arrivee,O)), !.


caseAdjacente(Depart,Arrivee):- Diff is Depart - Arrivee, element(Diff,[-1,1,-10,10]), !.


memeSens([E,_,_,'E'],Case,O) :- element((Case,O),E).
memeSens([_,R,_,'R'],Case,O) :- element((Case,O),R).


% Entrée sur le plateau sur case libre ou occupée
coup_possible(Plateau, (Depart,Arrivee,O)):- Depart = 0, verifCoupEntree((Depart,Arrivee,O)), verifEntree(Plateau, Depart), verifCase(Plateau, (Depart,Arrivee,O)).
% Déplacement sur case libre ou occupée
coup_possible(Plateau, (Depart,Arrivee,O)):- verifCoup((Depart,Arrivee,O)), Depart \= 0,
                                                caseAdjacente(Depart,Arrivee),
                                                case_occupee(Plateau,Depart,J),
                                                tourJoueur(Plateau,J),
                                                verifCase(Plateau,(Depart,Arrivee,O)).
% Changement d'orientation
coup_possible(Plateau, (X,X,O)):- verifCoup((X,X,O)), tourJoueur(Plateau,J), \+memeSens(Plateau,X,O), case_occupee(Plateau,X,J).
% Sortie de plateau
coup_possible(Plateau, (Depart,0,_)):- element(Depart, [11,12,13,14,15,21,31,41,51,25,35,45,52,53,54,55]), tourJoueur(Plateau,J), case_occupee(Plateau,Depart,J).


gain(0,J):- write('__________'), write('_________'), write('_________'), write('_________'), write('__________'), nl, nl,
               write('Victoire du joueur : '), write(J), nl, nl.
gain(_,_).


pousseur(L,J,Case,O,_,J):- element((Case,O),L), !.
pousseur(_,_,_,_,B,B).


% Rotation
bouger(_,_,[E,R,M,_],(X,X,_), E,R,M):- !.
% Elephant déplace Elephant
bouger('E',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isElephant([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(E,'E',Depart,O,B,NewB),
                                                             bouger('E',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),EInt,NewR,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(EInt,(Depart,_),(Arrivee,OF),NewE).
% Elephant déplace Rhinoceros
bouger('E',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isRhinoceros([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(E,'E',Depart,O,B,NewB),
                                                             bouger('R',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),EInt,NewR,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(EInt,(Depart,_),(Arrivee,OF),NewE).
% Elephant déplace Montagne
bouger('E',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isMontagne([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(E,'E',Depart,O,B,NewB),
                                                             bouger('M',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),EInt,NewR,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(EInt,(Depart,_),(Arrivee,OF),NewE).
% Elephant va sur case libre
bouger('E',_,[E,R,M,_],(Depart,Arrivee,_),NewE,R,M):- direction_case([E,R,_,_],Depart,OF), sed(E,(Depart,_),(Arrivee,OF),NewE).


% Rhinoceros deplace Elephant
bouger('R',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isElephant([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(R,'R',Depart,O,B,NewB),
                                                             bouger('E',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,RInt,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(RInt,(Depart,_),(Arrivee,OF),NewR).
% Rhinoceros deplace Rhinoceros
bouger('R',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isRhinoceros([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(R,'R',Depart,O,B,NewB),
                                                             bouger('R',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,RInt,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(RInt,(Depart,_),(Arrivee,OF),NewR).
% Rhinoceros deplace Montagne
bouger('R',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isMontagne([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             pousseur(R,'R',Depart,O,B,NewB),
                                                             bouger('M',NewB,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,RInt,NewM),
                                                             direction_case([E,R,_,_],Depart,OF),
                                                             sed(RInt,(Depart,_),(Arrivee,OF),NewR).
% Rhinoceros va sur case libre
bouger('R',_,[E,R,M,_],(Depart,Arrivee,_),E,NewR,M):- direction_case([E,R,_,_],Depart,OF), sed(R,(Depart,_),(Arrivee,OF),NewR).


% Montagne deplace Elephant
bouger('M',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isElephant([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             bouger('E',B,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,NewR,MInt),
                                                             sed(MInt,Depart,Arrivee,NewM).
% Montagne deplace Rhinoceros
bouger('M',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isRhinoceros([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             bouger('R',B,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,NewR,MInt),
                                                             sed(MInt,Depart,Arrivee,NewM).
% Montagne deplace Montagne
bouger('M',B,[E,R,M,_],(Depart,Arrivee,O),NewE,NewR,NewM):- isMontagne([E,R,M,_],Arrivee), !, caseSuiv(Arrivee,O,CaseSuiv),
                                                             bouger('M',B,[E,R,M,_],(Arrivee,CaseSuiv,O),NewE,NewR,MInt),
                                                             sed(MInt,Depart,Arrivee,NewM).
% Montagne va sur case libre
bouger('M',B,[E,R,M,_],(Depart,Arrivee,_), E,R,NewM):- sed(M,Depart,Arrivee,NewM), gain(Arrivee,B).


orienter(L,(_,Arrivee,O),NewL):- sed(L,(Arrivee,_),(Arrivee,O),NewL).


majPlateau([E,R,M,'E'],Coup,[NewE,NewR,NewM,'R']):- bouger('E','E',[E,R,M,_],Coup,IntE,NewR,NewM), orienter(IntE,Coup,NewE).
majPlateau([E,R,M,'R'],Coup,[NewE,NewR,NewM,'E']):- bouger('R','R',[E,R,M,_],Coup,NewE,IntR,NewM), orienter(IntR,Coup,NewR).

jouer_coup([E,R,M,J],_,_) :- element(0,M), !, affiche_plateau([E,R,M,J]), nl,nl, write('Fin de la partie').
jouer_coup(P,Coup,NewP) :- affiche_plateau(P),
                              repeat,
                              write('Veuillez saisir le coup : (Depart,Arrivee,Orientation).'), nl,
                              write('Depart/Arrivee : Numero de case'), nl,
                              write('Orientation: \'N\',\'S\',\'W\',\'E\''), nl,
                              read(Coup), nl,
                              coup_possible(P,Coup),
                              majPlateau(P,Coup,NewP), !,
                              jouer_coup(NewP,_,_).
% inutilisé
mauvaisCoup:-  write('Mauvais coup, veuillez choisir un autre coup.'), nl,
                  write('Format: (Depart,Arrivee,Orientation).'),nl,
                  write('Depart/Arrivee : Numero de case'), nl,
                  write('Orientation: \'N\',\'S\',\'W\',\'E\''), nl.


jouer :- plateauDepart(P),jouer_coup(P,_,_).


enlever(X,[X|Q],Q).
enlever(X,[Y|Q],[Y|R]) :- enlever(X,Q,R).


union([] , L , L ).
union([T|Q] ,L ,[T|Q1]) :- enlever(T,L,QL ),union(Q,QL,Q1).


concat([],L,L).
concat([T|Q],P,[T|R]) :-concat(Q,P,R).


coups_possibles(Plateau, ListeCoupsPossibles):- setof(C,coup_possible(Plateau,C),ListeCoupsPossibles).


testTest(L):- plateauTest(P), affiche_plateau(P), coups_possibles(P,L).
testDepart(L):- plateauDepart(P), affiche_plateau(P), coups_possibles(P,L).


% MinMax : max = Elephant, min = rhinocéros
% Determiner les coups gagnants


isnoBord(M):- \+member(M,[11,12,13,14,15,21,31,41,51,52,53,54,55,15,25,35,45]).
isBord(M):- member(M,[11,12,13,14,15,21,31,41,51,52,53,54,55,15,25,35,45]).


% il recoit un plateau et renvoie la liste des montagnes sur  le bord
montagnes([_,_,[],_],[]).
montagnes([_,_,[M|Q],_],L):- isnoBord(M),montagnes([_,_,Q,_],L),!.
montagnes([_,_,[M|Q],_],[M|L]) :- isBord(M),montagnes([_,_,Q,_],L).


coups_gagnants(P,[],[]):-!.
coups_gagnants(P,[(Depart,Arrivee,O)|Q],[(Depart,Arrivee,O)|L]) :- isMontagne(P,Arrivee),isBord(Arrivee),coups_gagnants(P,Q,L), !.
coups_gagnants(P,[_|Q],L):- coups_gagnants(P,Q,L).


setourner((_,_,'N'),(_,_,'S')).
setourner((_,_,'S'),(_,_,'N')).
setourner((_,_,'W'),(_,_,'E')).
setourner((_,_,'E'),(_,_,'W')).

reagir1(L,[],[]).
reagir1(L,[(Depart,Arrivee,O)|Q],[(Depart,Arrivee,O)|C]) :- member((D,A,Orien),L),setourner((D,A,Orien),(Depart,Arrivee,O)),\+poussee_possible(P,(D,A,Orien)),reagir1(L,Q,C),!.
reagir1(L,[(Depart,Arrivee,O)|Q],C) :- reagir1(L,Q,C).


tete(L,[L|_]).


reagir2(L,T) :-tete(T,L).


succ(X,Y,[(X,Y,_)|Q]).
succ(X,Y,[_|Q]) :- succ(X,Y,Q).


maximum(P,Q,Q) :- Q > P.
maximum(P,Q,P) :- P > Q.


nbPoussee([],0).
nbPousee([L|Q],Nb) :- nbPoussee(Q,Nb2), Nb is Nb2+1.


comptePoussee1([],[E,_,_,'E'],0).
comptePoussee1([(D,A,O)|L],[E,_,_,'E'],Nb):- D\=A,member(D,E),comptePoussee1(L,[E,_,_,'E'],Nb2), Nb is Nb2+1,!.
comptePoussee1([(D,A,O)|L],[E,_,_,'E'],Nb):- comptePoussee1(L,[E,_,_,'E'],Nb).


comptePoussee2([],[_,R,_,'R'],0).
comptePoussee2([(D,A,O)|L],[_,R,_,'R'],Nb):- D\=A,member(D,R),comptePoussee2(L,[_,R,_,'R'],Nb2), Nb is Nb2+1,!.
comptePoussee2([(D,A,O)|L],[_,R,_,'R'],Nb):- comptePoussee2(L,[_,R,_,'R'],Nb).

% gain immediat
meilleur_coup(P,C) :- coups_possibles(P,L), coups_gagnants(P,L,[C|_]).
% reagir 1
meilleur_coup([E,R,M,'R'],C) :- coups_possibles([E,R,M,'E'],L), coups_gagnants(P,L,L2),reagir1(L2,CG)
meilleur_coup([E,R,M,'E'],C) :- coups_possibles([E,R,M,'R'],L), coups_gagnants(P,L,L2),reagir1(L2,CG)
% reagir 2
meilleur_coup([E,R,M,'R'],C) :- coups_possibles([E,R,M,'E'],L), coups_gagnants(P,L,[C|_]).
meilleur_coup([E,R,M,'E'],C) :- coups_possibles([E,R,M,'R'],L), coups_gagnants(P,L,[C|_]).


jouer3 :-plateauDepart(P),jouer_coup3(P,_,_).
jouer4 :-plateauDepart(P),jouer_coup4(P,_,_).


jouer_coup2([E,R,M,J],_,_) :- element(0,M), !, affiche_plateau([E,R,M,J]), nl,nl, write('Fin de la partie').
jouer_coup2(P,Coup,NewP) :- affiche_plateau(P),
                              repeat,
                              meilleur_coup(P,Coup),
                              majPlateau(P,Coup,NewP),!,
                              jouer_coup3(NewP,_,_).


jouer_coup3([E,R,M,J],_,_) :- element(0,M), !, affiche_plateau([E,R,M,J]), nl,nl, write('Fin de la partie').
jouer_coup3(P,Coup,NewP) :- affiche_plateau(P),
                              repeat,
                              write('Veuillez saisir le coup : (Depart,Arrivee,Orientation).'), nl,
                              write('Depart/Arrivee : Numero de case'), nl,
                              write('Orientation: \'N\',\'S\',\'W\',\'E\''), nl,
                              read(Coup), nl,
                              coup_possible(P,Coup),
                              majPlateau(P,Coup,NewP), !,
                              jouer_coup2(NewP,_,_).






jouer_coup4([E,R,M,J],_,_) :- element(0,M), !, affiche_plateau([E,R,M,J]), nl,nl, write('Fin de la partie').
jouer_coup4(P,Coup,NewP) :- affiche_plateau(P),
                              repeat,
                              meilleur_coup(P,Coup),
                              majPlateau(P,Coup,NewP),!,
                              jouer_coup4(NewP,_,_).

choix_possible('hh').
choix_possible('hm').
choix_possible('mm').


choixmode(Choix) :-           repeat,
                      write('Veuillez saisir l\'un des trois modes '), nl,
                              write('hh. pour humain vs humain'), nl,
                          write('hm. pour homme machine, l\'homme controle l\'elephant'), nl,
                      write('mm. pour machine vs machine'), nl,
                      read(Choix),nl,
                              choix_possible(Choix),!, write('Vous avez choisi le mode : '),
                      write(Choix),nl.

jouer('hh'):- jouer.
jouer('hm') :- jouer3.
jouer('mm'):- jouer4.

jouer2 :- choixmode(Choix), jouer(Choix).
