/*
Package command implements the basic command set of extropy.

The functions in this package all perform a few basic operations:
* Type conversion on parameters
* Handling mandatory parameters
* Handle function outputs to the OS streams.

They may also handle some other requirements for mapping between a basic CLI
parameter and stronly typed parameters in the functions which actually
implement a given command.
*/
package command
