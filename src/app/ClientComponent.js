// src/app/ClientComponent.js

"use client";

import React, { useEffect, useState } from 'react';

const ClientComponent = () => {
  const [message, setMessage] = useState('');

  useEffect(() => {
    fetch('/api/hello')
      .then((response) => response.json())
      .then((data) => {
        console.debug("data: ",data)
        setMessage(data.message)
      });
  }, []);

  return (
    <div>
      <h2>Welcome to My Next.js App</h2>
      <p>The message from the API is: {message}</p>
    </div>
  );
};

export default ClientComponent;
