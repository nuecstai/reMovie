// Run this function when the page loads
document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('jwtToken');
    const userIcon = document.getElementById('userIcon');
    const userDropdown = document.getElementById('userDropdown');
    const usernameDisplay = document.getElementById('usernameDisplay');
    const loginButton = document.getElementById('loginButton');

    if (token) {
        // User is logged in, decode the token to get username
        const decoded = jwt_decode(token);
        const username = decoded.sub || decoded.name || decoded.Username;

        usernameDisplay.innerText = `Hello, ${username}`;
        loginButton.style.display = 'none'; // Hide login button
        userIcon.style.display = 'block';

        // Check if the user is an admin (username is 'admin')
        if (username === 'admin') {
            // Add admin dashboard button
            const adminButton = document.createElement('button');
            adminButton.innerText = 'Admin Dashboard';
            adminButton.onclick = () => window.location.href = 'admin-dashboard.html';
            adminButton.className = 'btn';
            userDropdown.appendChild(adminButton);
        }

    } else {
        // No user is logged in
        loginButton.style.display = 'block'; // Show login button
        userIcon.style.display = 'none'; // Hide user icon
    }

    userIcon.addEventListener('click', (event) => {
        // Prevent click event from propagating to the document
        event.stopPropagation();
        // Toggle the dropdown visibility
        userDropdown.style.display = userDropdown.style.display === 'block' ? 'none' : 'block';
    });

    // Close the dropdown if clicked outside of the user icon or dropdown
    document.addEventListener('click', (event) => {
        if (!userIcon.contains(event.target) && !userDropdown.contains(event.target)) {
            userDropdown.style.display = 'none'; // Hide the dropdown
        }
    });
});

// Logout function
function logout() {
    localStorage.removeItem('jwtToken');
    window.location.href = 'index.html';
}
