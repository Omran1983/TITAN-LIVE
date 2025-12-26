import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import "./index.css";

import App from "./App";
import Cockpit from "./pages/Cockpit";
import Agents from "./pages/Agents";
import Commands from "./pages/Commands";
import Projects from "./pages/Projects";
import Finance from "./pages/Finance";

const router = createBrowserRouter([
    {
        path: "/",
        element: <App />,
        children: [
            { index: true, element: <Cockpit /> },
            { path: "agents", element: <Agents /> },
            { path: "commands", element: <Commands /> },
            { path: "projects", element: <Projects /> },
            { path: "finance", element: <Finance /> },
        ],
    },
]);

ReactDOM.createRoot(document.getElementById("root")).render(
    <React.StrictMode>
        <RouterProvider router={router} />
    </React.StrictMode>
);
