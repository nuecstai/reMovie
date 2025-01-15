document.getElementById('signupForm').addEventListener('submit', async function (e) {
    e.preventDefault(); // Prevent the default form submission

    const email = document.getElementById('signupEmail').value;
    const username = document.getElementById('signupUsername').value;
    const password = document.getElementById('signupPassword').value;

    try {
        const response = await fetch('http://localhost:5000/api/auth/signup', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, username, password })
        });

        if (response.ok) {
            // If signup is successful, redirect to the login page
            alert('Signup successful! Please log in.');
            window.location.href = 'login.html'; // Redirect to login page
        } else {
            // Handle errors (e.g., user already exists)
            const errorData = await response.json();
            alert('Signup failed: ' + errorData.message); // Show error message from server
        }
    } catch (error) {
        console.error('Error during signup:', error);
        alert('An error occurred during signup. Please try again.');
    }
});

