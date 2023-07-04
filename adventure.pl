/* Dungeon of death, by Wiktor Kulesza, Jakub Tomaszewski, Filip. */

:- dynamic i_am_at/1, at/2, holding/1, locked/1.
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)).


/* These rules describe how to pick up an object. */

take(X) :-
        holding(X),
        write('You''re already holding it!'),
        !, nl.

take(X) :-
        i_am_at(Place),
        (at(X, Place); (at(Z, Place),at(X, Z), \+ locked(Z))),
        \+ tooHeavy(X),
        \+ disgusting(X),
        (at(X, Place) -> retract(at(X, Place)) ; retract(at(X, Z))),
        assert(holding(X)),
        write('OK.'),
        !, nl.

take(X) :-
        i_am_at(Place),
        (at(X, Place); (at(Z, Place),at(X, Z), \+ locked(Z))),
        tooHeavy(X),
        write('It\'s too heavy, can\'t take it...'), !, nl.

take(X) :-
        i_am_at(Place),
        (at(X, Place); (at(Z, Place),at(X, Z), \+ locked(Z))),
        \+ tooHeavy(X),
        disgusting(X),
        write('I\'m not mad, I won\'t take '), write(X), write('. It\'s so gross!'), !, nl.

take(_) :-
        write('I don''t see it here.'),
        nl.

/* These rules describe how to put down an object. */

drop(X) :-
        holding(X),
        i_am_at(Place),
        retract(holding(X)),
        assert(at(X, Place)),
        write('OK.'),
        !, nl.

drop(_) :-
        write('You aren''t holding it!'),
        nl.

/* These rules define the direction letters as calls to go/1. */

n :- go(n).

s :- go(s).

e :- go(e).

w :- go(w).

/* This rule tells how to move in a given direction. */

go(Direction) :-
        i_am_at(Here),
        path(Here, Direction, There),
        (canGo(Here, There) -> true ; hint(There), fail),
        (locked(There) -> retract(locked(There)) ; true ),
        (locked(Here) -> retract(locked(Here)) ; true ),
        retract(i_am_at(Here)),
        assert(i_am_at(There)),
        !, look.

        
go(_) :-
        write('You can''t go that way.'), nl.

canGo(_, Y) :- 
        (\+ locked(Y), isRoom(Y)) ; (isRoom(Y), forall(opens(Z, Y), holding(Z))).

/* Theese rules gives advice how to enter certain locations */
hint(throne_room) :-
        write('Those doors are so huge and seem to have realy complicated lock. It looks like there are 3 holes here, hmmm....'), nl,
        write('Perhaps I have to look for some kind of key or even few of them...'), nl, !.

hint(armory) :-
        write('Those doors are quite heavy and seem to have realy complicated lock.'), nl,
        write('Perhaps I have to look for some kind of key...'), nl, !.


hint(There) :-
        write('The door to the '), write(There ), write(' are locked! '), nl.

/* This rule tells how to look around you. */

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        notice_rooms_at(Place),
        nl.

/* This rule tells how to open an object. */

search(Object) :-
        at(Object, Place),
        i_am_at(Place),
        isOpenableItem(Object),
        can_open(Object),
        write('Searched '), write(Object), write('. You found: '), nl,
        (locked(Object) -> retract(locked(Object)); true), !,
        check_what_inside(Object, Place).
search(Object) :-
        at(Object, Place),
        i_am_at(Place),
        isOpenableItem(Object),
        \+ can_open(Object),
        write('Cannot open, perhaps you need some kind of '),
        needed_to_open(Object), !, nl.

search(Object) :-
        at(Object, Place),
        i_am_at(Place),
        \+ isOpenableItem(Object),
        write('That\'s not searchable object'), !, nl.

search(_) :-
        \+ (at(_, Place), i_am_at(Place)),
        write('There is no such an object in current location'), nl.

can_open(Object) :-
        \+ locked(Object) ; (locked(Object),holding(X), opens(X, Object)).

needed_to_open(armory) :-
        write('key'), !.

needed_to_open(_) :-
        write('key or pick.'), !.

check_what_inside(Object, _) :-
        at(FoundObject, Object),
        write(FoundObject), nl,
        false, nl.

/* These rules set up a loop to mention all the objects
   in your vicinity. */

notice_objects_at(armory) :-
        (\+ holding(torch), \+ at(torch, armory)),
        write('It\'s so dark here, can\'t see anything! Some light would be helpful...'), nl, !.
        

notice_objects_at(Place) :-
        write('You can see those objects in the room:'), nl,
        at(X, Place), 
        write(X), nl,
        false, nl.

notice_objects_at(_).

/* These rules set up a loop to mention all the rooms
   in your vicinity. */

notice_rooms_at(Place) :-
        nl, write('You can go to:'), nl,
        path(Place, Y, X),
        write(X), write(' on '), write(Y), write('. '), nl,
        fail.

/* These rules describe how attacking works */

attack(dragon) :-
        i_am_at(Here),
        at(Enemy, Here),
        isEnemy(Enemy),
        (holding(X), isWeapon(X)),
        win, !.

attack(princess) :-
        i_am_at(Here),
        at(princess, Here),
        (holding(X), isWeapon(X)),
        write('You monster! You killed your beloved one... Rot in hell!'), nl,
        die, !.

attack(Enemy) :-
        i_am_at(Here),
        at(Enemy, Here),
        (holding(X), isWeapon(X)),
        isEnemy(Enemy),
        write('Congratulate you killed '), write(Enemy), write('!'),
        (at(Enemy, Here) -> retract(at(Enemy, Here)); true), !.

attack(Enemy) :-
        i_am_at(Here),
        at(Enemy, Here),
        isEnemy(Enemy),
        \+ (holding(X), isWeapon(X)),
        write('Oh no, you don\'t have any weapon!'), nl,
        write(Enemy), write(' kills you.'), nl,
        die, !.

attack(Enemy) :-
        i_am_at(Here),
        at(Enemy, Here),
        \+ isEnemy(Enemy),
        \+ (holding(X), isWeapon(X)),
        write('You don\'t have any weapon to attack with....'), nl, !.

attack(Enemy) :-
        i_am_at(Here),
        at(Enemy, Here),
        \+ isEnemy(Enemy),
        write('That\'s not your enemy'), nl.

/* This rule tells how to die. */

die :-
        write('You\'ve lost'), nl,
        finish.


/* This rule tells how to win */

win :-
        write('My hero, Princess shouted. She run straight into your arms and kissed you on the lips.'), nl,
        write('You saved her one more time and let\'s hope it is your last time when you have to...'), nl,
        finish.


/* Under UNIX, the "halt." command quits Prolog but does not
   remove the output window. On a PC, however, the window
   disappears before the final output can be seen. Hence this
   routine requests the user to perform the final "halt." */

finish :-
        nl,
        write('The game is over. Please enter the "halt." command.'),
        nl.

/* This rule writes player's inventory. */

inventory :-
        write('Currently holding: '), nl,
        holding(X),
        write('- '), write(X), nl,
        false, nl.

i :-
        inventory.

/* This rule just writes out game instructions. */

instructions :-
        nl,
        write('Enter commands using standard Prolog syntax.'), nl,
        write('Available commands are:'), nl,
        write('start.             -- to start the game.'), nl,
        write('n.  s.  e.  w.     -- to go in that direction.'), nl,
        write('take(Object).      -- to pick up an object.'), nl,
        write('attack(Object).      -- to attack an object.'), nl,
        write('search(Object).      -- to try to search (open) an object'), nl,
        write('drop(Object).      -- to put down an object.'), nl,
        write('look.              -- to look around you again.'), nl,
        write('i.                 -- to list your inventory.'), nl,
        write('inventory.         -- to list your inventory.'), nl,
        write('instructions.      -- to see this message again.'), nl,
        write('halt.              -- to end the game and quit.'), nl,
        nl.




/* This rule prints out instructions and tells where you are. */

start :-
        instructions,
        look.

/* These relations describe rooms available in game */

isRoom(cellar).
isRoom(stairs).
isRoom(armory).
isRoom(grand_hall).
isRoom(dinning_hall).
isRoom(kitchen).
isRoom(barracks).
isRoom(throne_room).
isRoom(tower_stairs).
isRoom(observatory).

/* These relations describe items available in game */

isOpenableItem(wardrobe).
isOpenableItem(woodenChest).
isOpenableItem(ironChest).
isOpenableItem(desk).
isOpenableItem(bed).
isOpenableItem(corpses).
isWeapon(sword).
isItem(X) :- isOpenableItem(X); isWeapon(X).
isItem(torch).
isItem(key).
isItem(pick).
isItem(table).
isItem(bed).
isItem(corpses).
isItem(pile_of_bones).

tooHeavy(X) :-
        isOpenableItem(X).

tooHeavy(table).

disgusting(corpses).
disgusting(pile_of_bones).


/* These rules describe how paths between locations work*/

path2(cellar, s, armory).
path2(cellar, n, stairs).
path2(stairs, n, grand_hall).
path2(grand_hall, w, dinning_hall).
path2(grand_hall, e, barracks).
path2(grand_hall, n, throne_room).
path2(dinning_hall, n, kitchen).
path2(dinning_hall, w, tower_stairs).
path2(tower_stairs, s, observatory).

path(X, n, Y) :- path2(X, n, Y); path2(Y, s, X).
path(X, e, Y) :- path2(X, e, Y); path2(Y, w, X).
path(X, s, Y) :- path2(X, s, Y); path2(Y, n, X).
path(X, w, Y) :- path2(X, w, Y); path2(Y, e, X).

/* These rules describe how locked doors, chests and keys work */

locked(armory).
locked(woodenChest).
locked(ironChest).
locked(throne_room).

opens(key, armory).
opens(pick, woodenChest).
opens(pick, ironChest).
opens(keyFragment1, throne_room).
opens(keyFragment2, throne_room).
opens(keyFragment3, throne_room).

/* This section represents enemies */

isEnemy(dragon).

/* This section represents items and npcs set at map */

at(key, desk).
at(pick, wardrobe).
at(ironChest, kitchen).
at(woodenChest, barracks).
at(wardrobe, grand_hall).
at(desk, observatory).
at(sword, armory).
at(torch, stairs).
at(torch, tower_stairs).
at(keyFragment2, desk).
at(keyFragment1, woodenChest).
at(keyFragment3, ironChest).
at(dragon, throne_room).
at(princess, throne_room).
at(pile_of_bones, dinning_hall).
at(corpses, dinning_hall).
at(ring, corpses).
at(belt, bed).
at(bed, barracks).


/* These rules describe the various rooms.  Depending on
   circumstances, a room may have more than one description. */


/* describe(cellar) :- write('You are at cellar You\'re starving and have to find something to eat if you don\'t want to pass out'), nl. */
describe(A) :- write('You are at '), write(A), nl.

i_am_at(cellar).
