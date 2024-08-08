
export default (req, res) => {
    console.debug('=====')
    res.status(200).json({ message: 'Hello World' });
};