class EnqErrorException : System.Exception  { 
    $Node
    $EnqName

    EnqErrorException( [string]$message) : base($message) {

    }

    EnqErrorException() {

    }
}
try {
    CLS
    $MyError = [EnqErrorException]::new("Enqueue for resource xxx failed on node yyy")
    $MyError.Node = "ADHC"
    $MyError.EnqName = "WMI"

    throw $MyError
}
catch {
    $x = $error[0].Exception | Select-Object -Property * 
    $x
    $x.Message
    $x.node
    $x.enqname
}