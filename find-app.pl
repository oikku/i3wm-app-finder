#!/usr/bin/env swipl

:- initialization go.
:- use_module(library(http/json)).

get_windows(Output) :-
    process_create(
        path('i3-msg'), ['-t', 'get_tree'],
        [stdout(pipe(Out))]),
    json_read_dict(Out, Output),
    close(Out).

show_dmenu(Windows, Selected) :-
    process_create(
        path(dmenu), ['-i', '-l', 20],
        [stdout(pipe(Out)), stdin(pipe(In))]),
    print_names(In, Windows),
    close(In), 
    read_string(Out, _, S),
    close(Out),
    !,
    sub_string(S, _, _, 1, Selected).

select_window(Key, [W|_]) :-
    _{key:Key, id:Id} :< W,
    !,
    atomics_to_string(['[con_id="', Id, '"]'], Args),
    process_create(path('i3-msg'), [Args, focus], []).
select_window(Key, [_|T]) :- select_window(Key, T).


ignore_window(Window) :- false = Window.geometry.
ignore_window(Window) :-
    _{window_properties: Props} :< Window,
    get_dict(class, Props, "i3bar").
ignore_window(Window) :- 
    _{width: 0, height: 0} :< Window.geometry.

parse_window(Window, Out, Parent) :-
    ignore_window(Window),
    _{nodes: Nodes, name:Name} :< Window,
    set_parent(Name, Parent, P),
    parse_window_list(Nodes, Out, P).
parse_window(Window, [R|Out], Parent) :-
    _{id: Id, name: Name, focused: Focused, nodes: Nodes} :< Window,
    set_parent(Name, Parent, P),
    atomics_to_string(['[', Parent ,'] ', Name,' (', Id, ')'], Key),
    R = _{id:Id, name:Name, focused: Focused, key:Key},
    parse_window_list(Nodes, Out, P).

set_parent(null, Parent, Parent).
set_parent(Name, _, Name) :- \+ Name = null.

parse_window_list([Window|T], Out, Parent) :-
    parse_window(Window, O1, Parent),
    parse_window_list(T, O2, Parent),
    lists:append(O1, O2, Out).
parse_window_list([], [], _).

print_names(_, []).
print_names(In, [H|T]) :-
    _{key:Key} :< H,
    writeln(In, Key),
    print_names(In, T).

go :-
    catch(
        run_selection, 
        E, 
        (print_message(error, E), fail)
    ),
    halt(0).
go :- halt(1).

run_selection :-
    get_windows(W),
    parse_window(W, R, ""),
    show_dmenu(R, Selected),
    select_window(Selected, R).
