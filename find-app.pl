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


ignore_window(Window) :- get_dict(geometry, Window, false).
ignore_window(Window) :-
    _{window_properties: Props} :< Window,
    get_dict(class, Props, "i3bar").
ignore_window(Window) :- 
    _{geometry: Geometry} :< Window,
    _{width: 0, height: 0} :< Geometry.

parse_window_tree([], [], _).
parse_window_tree([H|T], Out, Parent) :-
    parse_window(H, W, Parent),
    parse_window_tree(T, R, Parent),
    lists:append(W, R, Out).

parse_window(In, Out, Parent) :-
    ignore_window(In),
    _{nodes: Nodes, name:Name} :< In,
    !,
    (Name = null -> P = Parent; P = Name),
    parse_window_tree(Nodes, Out, P).
parse_window(In, Out, Parent) :-
    _{id: Id, name: Name, focused: Focused, nodes: Nodes} :< In,
    !,
    (Name = null -> P = Parent; P = Name),
    parse_window_tree(Nodes, R, P),
    atomics_to_string(['[', Parent ,'] ', Name,' (', Id, ')'], Key),
    lists:append([ _{id:Id, name:Name, focused: Focused, key:Key} ], R, Out).
parse_window(_, [], _).

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
