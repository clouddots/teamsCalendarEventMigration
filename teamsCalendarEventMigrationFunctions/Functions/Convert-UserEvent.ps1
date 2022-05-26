function Convert-UserEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][PSObject]$UserEvent,
        [Parameter(Mandatory = $false)][datetime]$CutOver,
        [Parameter(Mandatory)][string]$SubjectAppend

    )
    $Body = @{}
    if ($UserEvent.subject) {
        if ($SubjectAppend) {
            $Subject = $SubjectAppend + " - " + $UserEvent.subject
        }
        else {
            $Subject = $UserEvent.subject
        }
        $body.subject = $Subject
    }
    if ($UserEvent.body.content) {
        $updateContent = Remove-TeamsEventInfo -html $UserEvent.body.content
        $bodyContent = [PSCustomObject]@{
            contentType = "HTML"
            content     = $updateContent
        }
        $body.body = $bodycontent
    }
    if ($UserEvent.start) {
        $body.start = $UserEvent.start
    }
    if ($UserEvent.end) {
        $body.end = $UserEvent.end
    }
    if ($UserEvent.recurrence) {
        $recurrence = $UserEvent.recurrence
        if ($CutOver) {
            [string]$CutOver = $CutOver.ToString("yyyy-MM-dd")
            $recurrence.range.startDate = $CutOver
        }
        $body.recurrence = $UserEvent.recurrence
    }
    if ($UserEvent.location.displayName) {
        $location = [PSCustomObject]@{
            displayName = $UserEvent.location.displayName
        }
        $body.location.displayName = $location
    }
    if ($UserEvent.attendees) {
        $array = @(
            foreach ($attendeeItem in $UserEvent.attendees) {
                $attendees = @{}
                $emailAddress = [PSCustomObject]@{
                    address = $attendeeItem.emailAddress.address
                    name    = $attendeeItem.emailAddress.name
                }
                $attendees.emailaddress = $emailAddress
                $type = $attendeeItem.type
                $attendees.type = $type
                $attendees
            })
        $body.attendees = $array
    }
    if ($UserEvent.allowNewTimeProposals) {
        $allowNewTimeProposals = $UserEvent.allowNewTimeProposals
        $body.allowNewTimeProposals = $allowNewTimeProposals
    }
    $body.isOnlineMeeting = "true"
    $body.onlineMeetingProvider = "teamsForBusiness"

    $account_params = @{
        Headers     = @{Authorization = "Bearer $($GraphAPIKey)" }
        Uri         = "https://graph.microsoft.com/$GraphVersion/users/$($UserEvent.organizer.emailaddress.address)/events"
        body        = $Body | ConvertTo-Json -Depth 10
        Method      = 'POST'
        ContentType = 'application/json'
    }
    Invoke-RestMethod @Account_params
}