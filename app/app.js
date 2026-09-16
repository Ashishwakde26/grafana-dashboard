const fs = require("fs");
const path = require("path");
const express = require("express");
const client = require("prom-client");
const usersFile = path.join(__dirname, "users.json");
const ordersFile = path.join(__dirname, "orders.json");


function readOrders() {
  if (!fs.existsSync(ordersFile)) {
    fs.writeFileSync(ordersFile, JSON.stringify([], null, 2));
  }

  return JSON.parse(fs.readFileSync(ordersFile, "utf-8"));
}

function saveOrders(orders) {
  fs.writeFileSync(
    ordersFile,
    JSON.stringify(orders, null, 2)
  );
}


function authenticateUser(username, password) {
  const users = readUsers();

  return users.find(
    user =>
      user.username === username &&
      user.password === password
  );
}


function readUsers() {
  if (!fs.existsSync(usersFile)) {
    fs.writeFileSync(usersFile, JSON.stringify([], null, 2));
  }

  return JSON.parse(fs.readFileSync(usersFile, "utf-8"));
}

function saveUsers(users) {
  fs.writeFileSync(
    usersFile,
    JSON.stringify(users, null, 2)
  );
}

function logError(message, requestPath, reqBody) {
    console.error(JSON.stringify({
        timestamp: new Date().toISOString(),
        level: "error",
        request: requestPath,
        message: message,
        reqBody: reqBody
    }));
}

const app = express();
app.use(express.json());

const PORT = 3000;

// --------------------------------------------------
// Prometheus default Node.js metrics
// --------------------------------------------------

client.collectDefaultMetrics();


// --------------------------------------------------
// Custom HTTP metrics
// --------------------------------------------------

const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "status", "path"],
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["method", "path", "status"],
  buckets: [0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
});

const httpResponseSize = new client.Counter({
  name: "http_response_size_bytes",
  help: "Total HTTP response size in bytes",
  labelNames: ["method", "path"],
});

const httpStatusCodes = new client.Counter({
  name: "http_status_codes",
  help: "Total HTTP responses by status code",
  labelNames: ["status"],
});


// --------------------------------------------------
// HTTP logging + metrics middleware
// --------------------------------------------------

app.use((req, res, next) => {

  // Don't log Prometheus scraping
  if (req.path === "/metrics") {
    return next();
  }

  const start = process.hrtime.bigint();

  res.on("finish", () => {

    const end = process.hrtime.bigint();

    const duration =
      Number(end - start) / 1_000_000_000;

    const method = req.method;
    const path = req.originalUrl || req.url;
    const status = String(res.statusCode);

    const host =
      req.headers["x-forwarded-for"]?.split(",")[0]?.trim()
      || req.socket.remoteAddress
      || "-";

    const referer =
      req.headers.referer ||
      "-";

    const bytes =
      Number(res.getHeader("Content-Length")) || 0;

    // ------------------------------------------------
    // Structured JSON log
    // ------------------------------------------------

    const log = {
      timestamp: new Date().toISOString(),
      level: "info",
      host,
      method,
      request: path,
      status: res.statusCode,
      bytes,
      duration_ms: Math.round(duration * 1000),
      referer
    };

    console.log(JSON.stringify(log));


    // ------------------------------------------------
    // Prometheus metrics
    // ------------------------------------------------

    httpRequestsTotal.inc({
      method,
      status,
      path
    });

    httpRequestDuration.observe(
      {
        method,
        path,
        status
      },
      duration
    );

    httpStatusCodes.inc({
      status
    });

    if (bytes > 0) {
      httpResponseSize.inc(
        {
          method,
          path
        },
        bytes
      );
    }

  });

  next();
});


// --------------------------------------------------
// Application APIs
// --------------------------------------------------


// Get all orders (no authentication required)
app.get("/allorders", (req, res) => {
  const orders = readOrders();
  res.status(200).json(orders);
});


app.get("/randomorderid", (req, res) => {
  const orders = readOrders();

  if (!orders || orders.length === 0) {
    return res.status(404).json({
      message: "No orders found"
    });
  }

  const randomOrder = orders[Math.floor(Math.random() * orders.length)];

  res.status(200).json({
    orderId: randomOrder.id
  });
});


app.delete("/orders", (req, res) => {
//  const { username, password } = req.body;
  const { orderId } = req.body;

  console.log("Delete order request: ", orderId)

  // Validate request
  if (!orderId) {
    logError(
      "order ID is required",
      req.path,
      req.body
    );

    return res.status(400).json({
      error: "order ID is required"
    });
  }

  // Read existing orders
  const orders = readOrders();

  console.log("Order details as: ", JSON.stringify(orders))

  // Find the order
  const orderIndex = orders.findIndex(
    order =>
      String(order.id) === String(orderId) 
  );

  // Order not found or doesn't belong to user
  if (orderIndex === -1) {
    logError(
      "Order not found or does not belong to user",
      req.path,
      req.body
    );

    return res.status(404).json({
      error: "Order not found"
    });
  }

  // Remove order
  const deletedOrder = orders.splice(orderIndex, 1)[0];

  // Save updated orders
  saveOrders(orders);

  res.status(200).json({
    message: "Order deleted successfully",
    order: deletedOrder
  });
});


app.post("/ordercreate", (req, res) => {
  const { username, password, order } = req.body;

  // Validate request
  if (!username || !password || !order) {
    logError("Username, password and order details are required", req.path, req.body);
    return res.status(400).json({
      error: "Username, password and order details are required"
    });
  }

  // Authenticate user
  const user = authenticateUser(username, password);

  if (!user) {
    logError("Invalid username or password", req.path, req.body);
    return res.status(401).json({
      error: "Invalid username or password"
    });
  }

  // Read existing orders
  const orders = readOrders();

  // Create new order
  const newOrder = {
    id: Date.now(),
    username: username,
    order: order,
    createdAt: new Date().toISOString()
  };

  // Add order
  orders.push(newOrder);

  // Save orders
  saveOrders(orders);

  res.status(201).json({
    message: "Order created successfully",
    order: newOrder
  });
});


app.post("/login", (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    logError('Username and Password must be present while login', req.path, req.body);
    return res.status(400).json({
      error: "Username and password are required"
    });
  }

  const users = readUsers();

  const user = users.find(
    user =>
      user.username === username &&
      user.password === password
  );

  if (!user) {
    logError("Username and Password are incorrect", req.path, req.body);
    return res.status(401).json({
      error: "Invalid username or password"
    });
  }

  res.status(200).json({
    message: "Login successful"
  });
});



app.post("/register", (req, res) => {
  const { username, password } = req.body;

  // Validate username
  if (!username) {
    logError("Username is required", req.path, req.body);
    return res.status(400).json({
      error: "Username is required"
    });
  }

  // First character must be uppercase
  if (!/^[A-Z]/.test(username)) {
    logError("Username must start with an uppercase letter", req.path, req.body);
    return res.status(400).json({
      error: "Username must start with an uppercase letter"
    });
  }

  // Validate password
  if (!password) {
    logError("Password is required", req.path, req.body);
    return res.status(400).json({
      error: "Password is required"
    });
  }

  const users = readUsers();

  // Check whether user already exists
  const existingUser = users.find(
    user => user.username === username
  );

  if (existingUser) {
    logError("Username already exists", req.path, req.body);
    return res.status(409).json({
      error: "Username already exists"
    });
  }

  // Save user
  users.push({
    username,
    password
  });

  saveUsers(users);

  res.status(201).json({
    message: "User registered successfully"
  });
});


app.get("/users", (req, res) => {
  const users = readUsers();

  const usersWithoutPasswords = users.map(user => ({
    username: user.username
  }));

  res.status(200).json(usersWithoutPasswords);
});


app.post("/orders", (req, res) => {
  const { username, password } = req.body;

  // Validate request
  if (!username || !password) {
    logError("Username and password are required", req.path, req.body);
    return res.status(400).json({
      error: "Username and password are required"
    });
  }

  // Authenticate user
  const user = authenticateUser(username, password);

  if (!user) {
    logError("Invalid username or password", req.path, req.body);
    return res.status(401).json({
      error: "Invalid username or password"
    });
  }

  // Read all orders
  const orders = readOrders();

  // Get orders belonging to this user
  const userOrders = orders.filter(
    order => order.username === username
  );

  res.status(200).json(userOrders);
});


app.get("/error", (req, res) => {
  logError("Something went wrong", req.path, req.body);
  res.status(500).json({
    error: "Something went wrong"
  });

});


// --------------------------------------------------
// Prometheus endpoint
// --------------------------------------------------

app.get("/metrics", async (req, res) => {

  res.set(
    "Content-Type",
    client.register.contentType
  );

  res.end(
    await client.register.metrics()
  );

});


// --------------------------------------------------
// Start application
// --------------------------------------------------

app.listen(PORT, () => {

  console.log(
    `Node.js application listening on port ${PORT}`
  );

});