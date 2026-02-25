import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Layout } from './components/layout/Layout';
import ReviewQueue from './views/ReviewQueue';
import SentTable from './views/SentTable';
import RejectedLeads from './views/RejectedLeads';
import AllLeads from './views/AllLeads';
import StatsDashboard from './views/StatsDashboard';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<ReviewQueue />} />
          <Route path="sent" element={<SentTable />} />
          <Route path="rejected" element={<RejectedLeads />} />
          <Route path="all" element={<AllLeads />} />
          <Route path="dashboard" element={<StatsDashboard />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
