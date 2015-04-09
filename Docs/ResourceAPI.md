Every roblox instance can be coupled to an Instinct object with the same name

Instinct objets provide an extention of the roblox instance and provide additional data for the services to do their jobs. These basically check which actions are possible on a certain resource.

In order to keep this organized, everything is considered to be in the namespace of the object. However, for some "global" functions, it is necessary that these are defined elsewhere.

Instinct Objects are the higest abstraction level of Instances as interpreted by Instinct. However, these can be subdivided into groups - Instinct does NOT consider these though.

Resources
==========

Resources are the basic Instinct Object data container. These provide additional data, such as hardness, rarity, material, etc. Every instinct object has the following important handles;

** CheckGather ** [IMPLEMENTED]
A function which is used to figure out if a resource can be gathered or not. Should return the following arguments;

bool CanGather [essential] provides info if the resource can be gathered with the given input arguments.
*	list/string Messages [optional]
*	Can be used for info strings to the UI. Warning strings or other styled strings are also provided. Must be a list of items. If item is a string, put it in "info" if CanGather and in "warn" if not CanGather. Styles can be hardcoded by putting a table with the Style and Text element ste.
*	string/List necessaryAction. Should return a string or a list of strings of action identifiers which are necessary to gather this resource. For instance, ores can be gathered via the "Mine" action, which belongs to the "Pickaxe" tool.

Tools 
=======

Tools differ from resources, because these commonly have fields to describe what actions these do, besides their "Default actions"

In general, this resource should have a field with AvailableActions. This should be a list-table with Action-Identifier strings which define which actions are possible for the tool.

Actions
------------

### Action Order

Every tool (or, as always, every *object*) has an ActionList - this list is appended by the DefaultAction list, declared by the "Default" action group of IntentionService. The high-priority actions should go first. If an Action's RUN field returns *true* then the rest of the list will NOT be checked.

For example, an Axe can have the {"Chop"} ActionList. Chop should be defined in /Data/Actions where it should be put into the "Tool" action group.

### Action Structure

Every action NEEDS a :Cache and a :Run field. 

Cache (input: Target, UsedTool) where Target is an Instance and UsedTool is a instinct tool object, describing the used tool. Cache returns a boolean if the action can be done or not. Note that Cache is also used by IntentionService:GetOption which figures out what action the tool can take on the current target.

The result is saved in the Tool cache for the current target.

Run (input: Target, UsedTool) Runs the given action. This should **NOT** be called directly - this should be done via IntentionService. This service should first delete the cache and re-cache to figure out if the action is still OK to do. This should return a boolean. If this is true, the service will ping to the server tha the :RunServer field should be called, with the same arguments. Note that an Instinct Tool does not exist on the server, which means that the ToolRoot is passed instead. This should not be a problem as server can get the relevant data from ObjectService. Client data shouldn't be on the server anyways as that is local.

RunServer (input: Target, ToolRoot) where ToolRoot is the actual ToolRoot instance from the database. Runs given action on the server as ordered by Run from client. if possible this service can be expanded to accept arguments from the Run function. Shouldn't be a big problem when taht issue arises.

That shoudl actually be added. For instance, the Knapping action can let Run yield (!!!) and then return true to call the server, given the arguments. Should be implemented.


### Action Order

This mainly concerns how the handler script should interpert and handle the IntentionService:GetOption funciton. This funciton retrieves the following data;

*	What tools do I currently have equipped?
*	What actions can I perform with the current tools?
*	What actions can I currently perform *without* my tools? 
*	Can I move the target?
*	Can I gather the target?

These actions are returned. Default actions should go left. This could include inspecting someone's backpack, shaking a tree or even gathering itself. However this would re-call the GetOption function so this is not a good idea to implement. We can just put that on the script side.

Simple flowchart for actions:

:GetOption should NOT be called when not "focussed" on doing a gather or another action, for instance, when using the Build or Move tool 
-> Check left tool. Has action? Bind left action click to Run that action.
->? Check right tool. Has action? Bin right action to Run that action.
-> If no action has been defined for left, figure out if a default action can be done, if so, push that
-> Elseif cangather -> Put gather on high prio ist
