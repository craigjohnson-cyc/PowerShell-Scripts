new-item alias:/clr -value "clear-host"


# Example of a function that will process each item passed to
# it from a pipeline (Implicit for-each)
function add-hg
{
    param(
        [Parameter( ValueFromPipelineByPropertyName=$true ) ]
        [alias('fullname')]                                          #If the incomming object does not have a property called 'path', it will use the property 'fullname' as 'path'
        $path
    )

    process
    {
        #some code block to be applied to each object
    }
}

#Example of running the above function
get-hgstatus "?" | add-hg;

#Example of running the above function where the alias 'fullname' will be used instead of 'path' because dir does not contain a property path
#  get a list of all files starting with the word 'file' and have a size greater than 0 and remove them from source control
dir file* | where { $_.length -gt 0 } | remove-hg

#Change the powershell prompt
function prompt
{
    write-host 'PS ' -nonewline;
    write-host $pwd -foreground cyan -nonewline
    ' > '
}

#Reset the prompt to default
function prompt { "PS $pwd> " }

