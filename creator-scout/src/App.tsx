import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Layout } from './components/layout/Layout';
import ReviewQueue from './views/ReviewQueue';
import ApprovedLeads from './views/ApprovedLeads';
import RejectedLeads from './views/RejectedLeads';
import AllLeads from './views/AllLeads';
import StatsDashboard from './views/StatsDashboard';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<ReviewQueue />} />
          <Route path="approved" element={<ApprovedLeads />} />
          <Route path="rejected" element={<RejectedLeads />} />
          <Route path="all" element={<AllLeads />} />
          <Route path="stats" element={<StatsDashboard />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
