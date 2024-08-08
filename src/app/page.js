import React from 'react';
import ClientComponent from './ClientComponent';

export const metadata = {
  title: 'Home Page',
  description: 'Welcome to My Next.js App',
};

const HomePage = () => {
  return (
    <div>
      <ClientComponent />
    </div>
  );
};

export default HomePage;