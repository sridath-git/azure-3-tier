var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

var routes = require('./routes/index');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// uncomment after placing your favicon in /public
// app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// ✅ health check endpoint for Azure App Service
app.get('/health', function (req, res) {
    res.status(200).send('ok');
});

app.use('/', routes);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

// error handlers

// development error handler (prints stacktrace)
if (app.get('env') === 'development') {
    app.use(function (err, req, res, next) {
        res.status(err.status || 500);

        // ✅ res.render needs a view name
        // If you have views/error.jade, this will render it.
        // Otherwise it will fall back to JSON below.
        if (app.get('view engine')) {
            return res.render('error', {
                message: err.message,
                error: err
            });
        }

        return res.json({ message: err.message, error: err });
    });
}

// production error handler (no stacktraces leaked)
app.use(function (err, req, res, next) {
    res.status(err.status || 500);

    // ✅ res.render needs a view name
    if (app.get('view engine')) {
        return res.render('error', {
            message: err.message,
            error: {}
        });
    }

    return res.json({ message: err.message, error: {} });
});

module.exports = app;
