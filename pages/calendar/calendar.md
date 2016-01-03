---
title: About Us
order: 400
---

<link rel='stylesheet' href='/css/fullcalendar.css' />

<script src="/js/fullcalendar-2.5.0/lib/jquery.min.js"></script>
<script src="/js/fullcalendar-2.5.0/lib/moment.min.js"></script>
<script src="/js/fullcalendar-2.5.0/fullcalendar.min.js"></script>
<script src="/js/fullcalendar-2.5.0/gcal.js"></script>

<div id="calendar">
</div>


<script>

$(document).ready(function() {
    $('#calendar').fullCalendar({
        eventLimit: true,
        googleCalendarApiKey: 'AIzaSyA8L5BF8FfCTV1X8Ce8B55aYaz4nqDrSAM',
        eventSources: [
            {
                googleCalendarId: 'villasinfoniasfo@gmail.com'
            },
            {
                googleCalendarId: 'villacelloevents@google.com'
            },
            {
              googleCalendarId: 'villaorchestra@gmail.com'
            },
            {
              googleCalendarId: 'villaperformances@gmail.com'
            },
            {
              googleCalendarId: 'villaviolinevents@gmail.com'
            },
        ],
        views: {
          month: {
              eventLimit: 1
          }
        },
        fixedWeekCount: false,
        header: {
    left:   'prev',
    center: 'title',
    right:  'next'
},
height: "auto"
    });
});
</script>
