document.getElementById('loginForm').addEventListener('submit', async function (e) {
    e.preventDefault(); // Prevent the default form submission

    const username = document.getElementById('loginUsername').value;
    const password = document.getElementById('loginPassword').value;

    console.log('Logging in with:', { email: username, password });

    try {
        const response = await fetch('http://localhost:5000/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });

        console.log('Response status:', response.status);

        if (response.ok) {
            const data = await response.json();
            alert('Login successful!');
            localStorage.setItem('jwtToken', data.token); // Store token in local storage
            window.location.href = 'index.html';
        } else {
            // Handle errors (e.g., invalid credentials)
            const errorData = await response.json();
            alert('Login failed: ' + errorData.message); // Show error message from server
        }
    } catch (error) {
        console.error('Error during login:', error);
        alert('An error occurred during login. Please try again.');
    }
});
